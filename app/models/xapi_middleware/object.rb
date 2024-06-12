# frozen_string_literal: true

# The Object defines the thing that was acted on.
# See: https://github.com/adlnet/xAPI-Spec/blob/master/xAPI-Data.md#244-object
# The Object of a Statement can be an Activity, Agent/Group, SubStatement, or Statement Reference.
class XapiMiddleware::Object
  OBJECT_TYPES = ["Activity", "Agent", "Group", "SubStatement", "StatementRef"]

  attr_accessor :object_type, :id, :definition
  attr_reader :verb, :object, :actor

  # Initializes a new Object instance.
  #
  # @param [Hash] object The object hash containing id and definition.
  def initialize(object)
    if object.blank? || object.nil?
      raise XapiMiddleware::Errors::XapiError,
        I18n.t("xapi_middleware.errors.missing_object", name: "object")
    end

    validate_object(object)
    normalized_object = normalize_object(object)

    @object_type = normalized_object[:objectType]
    @id = object[:id].presence
    @definition = object[:definition].present? ? XapiMiddleware::ObjectDefinition.new(object[:definition]) : nil
    # In the case of a SubStatement:
    @verb = normalized_object[:verb].presence
    @object = normalized_object[:object].presence
    @actor = normalized_object[:actor].presence
  end

  # Validates the object data.
  #
  # @param [Hash] object The object data.
  def validate_object(object)
    object_type = object[:objectType]

    # Raise an error if the object has no ID, except for a SubStatement object.
    if object[:id].blank? && !statementref_or_substatement?(object)
      raise XapiMiddleware::Errors::XapiError, I18n.t("xapi_middleware.errors.missing_object_keys", keys: "id")
    end

    if object_type.present?
      object_type_valid = OBJECT_TYPES.include?(object_type)

      unless object_type_valid
        raise XapiMiddleware::Errors::XapiError, I18n.t("xapi_middleware.errors.invalid_object_object_type", name: object_type)
      end
    end

    if object_type.present? && statementref_or_substatement?(object)
      is_valid_substatement = object[:actor].present? && object[:object].present? && object[:verb].present?

      unless is_valid_substatement || statementref?(object)
        raise XapiMiddleware::Errors::XapiError, I18n.t("xapi_middleware.errors.invalid_object_substatement")
      end
    end
  end

  # Normalizes the object data.
  #
  # @param [Hash] object The actor data.
  # @return [Hash] The normalized object data.
  def normalize_object(object)
    normalized_object_type = object[:objectType].presence || OBJECT_TYPES.first
    normalize_substatement_verb, normalize_substatement_object, normalize_substatement_actor = nil

    if normalized_object_type == "SubStatement"
      # Validate the substatement object first.
      validate_object(object[:object])
      # Normalize the substatement data.
      normalize_substatement_verb = object[:verb]
      normalize_substatement_object = object[:object]
      normalize_substatement_actor = object[:actor]
    end

    {
      objectType: normalized_object_type,
      verb: normalize_substatement_verb,
      object: normalize_substatement_object,
      actor: normalize_substatement_actor
    }.compact
  end

  # Overrides the Hash class method.
  #
  # @return [Hash] The object hash.
  def to_hash
    {
      objectType: @object_type,
      id: @id,
      definition: @definition,
      verb: @verb,
      object: @object,
      actor: @actor
    }.compact
  end

  private

  def statementref?(object)
    return true if object[:objectType] == "StatementRef"

    false
  end

  def statementref_or_substatement?(object)
    is_substatement = object[:objectType] == "SubStatement"
    is_statement_ref = statementref?(object)

    # Raise an error if the SubStatement object has an ID.
    if object[:id].present? && is_substatement
      raise XapiMiddleware::Errors::XapiError, I18n.t("xapi_middleware.errors.unexpected_substatement_object_keys", keys: "id")
    end

    return true if is_substatement || is_statement_ref

    false
  end
end
