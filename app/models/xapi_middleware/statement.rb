# frozen_string_literal: true

module XapiMiddleware
  class Statement < ApplicationRecord
    attr_accessor :object, :actor, :result

    after_initialize :set_data

    validates :verb_id, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "is not a valid URL" }
    validates :object_identifier, presence: true
    validates :actor_name, presence: true
    validates :statement_json, presence: true

    def set_data
      @verb = XapiMiddleware::Verb.new(verb_id)
      @actor = XapiMiddleware::Actor.new(actor)
      @object = XapiMiddleware::Object.new(object)
      @result = XapiMiddleware::Result.new(result) if result.present?
      self.object_identifier = @object.id
      self.actor_name = @actor.name
      self.statement_json = prepare_json
    end

    def output
      log_output if XapiMiddleware.configuration.output_xapi_logs
      self
    end

    def pretty_print
      JSON.pretty_generate(as_json)
    end

    private

      def prepare_json
        {
          verb: @verb,
          object: @object,
          actor: @actor,
          result: @result
        }.to_json
      end

      def log_output
        Rails.logger.info "#{I18n.t("xapi_middleware.xapi_statement")} => #{pretty_print}"
      end
  end
end
