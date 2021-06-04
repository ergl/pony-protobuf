use ".."
use "collections"

class val FieldMeta
  let number: I32
  let tag_kind: TagKind
  let typ: String
  let default: String
  let is_packed: Bool

  new val create(
    number': I32,
    tag_kind': TagKind,
    typ': String,
    default': String,
    is_packed': Bool = false)
  =>
    number = number'
    tag_kind = tag_kind'
    typ = typ'
    default = default'
    is_packed = is_packed'

primitive CodeGenFields
  fun apply(
    writer: CodeGenWriter ref,
    template_ctx: GenTemplate,
    scope: SymbolScope,
    fields: Array[FieldDescriptorProto])
    : Map[String, FieldMeta] val
  =>
    // Mapping of fields to its field number and kind
    let field_meta = recover Map[String, FieldMeta] end
    let field_numbers = Map[String, (U64, TagKind)]
    for field in fields.values() do
      try
        let name = GenNames.message_field(field.name as String)
        let field_number = field.number as I32
        (let field_tag, let field_type, let default) = _find_field_type(field,
          field.label as FieldDescriptorProtoLabel, scope)?
        let is_packed =
          try (field.options as FieldOptions).packed as Bool else false end
        field_meta(name) =
          FieldMeta(where
            number' = field_number,
            tag_kind' = field_tag,
            typ' = field_type,
            default' = default,
            is_packed' = is_packed
          )
      end // TODO(borja): What do we do about anonymous messages?
    end
    consume field_meta

  fun _find_field_type(
    field: FieldDescriptorProto,
    field_label: FieldDescriptorProtoLabel,
    scope: SymbolScope)
    : (TagKind, String, String)
    ?
  =>

    let default_value_str = match field.default_value
    | let default_value': String => default_value'
    | None => "None"
    end

    match field.field_type
    | let field_type: FieldDescriptorProtoType =>
      match GenTypes.typeof(field_type, field_label, default_value_str)
      | let field_tag: TagKind =>
        // We couldn't decipher the type, it's possible that it's a
        // message or enum type.
        (
          field_tag,
          GenTypes.label_of(
            scope(field.type_name as String) as String,
            field_label
          ),
          _find_default(
            scope,
            field.type_name as String,
            default_value_str,
            field_label
          )?
        )

      | (
          let field_tag: TagKind,
          let type_name: String,
          let default_value: String
        ) =>
        // Everything went OK
        (field_tag, type_name, default_value)
      end
    else
      // Allowed, but type_name better be set.
      // We assume that this is a message type
      (
        DelimitedField,
        GenTypes.label_of(
          scope(field.type_name as String) as String,
          field_label
        ),
        _find_default(
          scope,
          field.type_name as String,
          default_value_str,
          field_label
        )?
      )
    end

  fun _find_default(
    scope: SymbolScope,
    type_name: String,
    default: String,
    label: FieldDescriptorProtoLabel)
    : String
    ?
  =>
    let has_default = default != "None"
    if
      (not has_default) and
      (label isnt FieldDescriptorProtoLabelLABELREPEATED)
    then
      return "None"
    end

    GenTypes.default_value(
      if has_default then
        scope(default) as String
      else
        scope(type_name) as String
      end,
      label
    )
