module Redactable
  extend ActiveSupport::Concern

  included do
    class_attribute :redactable_attrs, default: []

    delegate :apply_masks, to: :info_request

    attr_writer :unredacted_access
  end

  class_methods do
    # Declare attributes/methods whose values may contain personal data.
    # Direct access returns redacted content; use #unredacted to access raw values.
    def redactable(*attrs)
      self.redactable_attrs = attrs

      prepend(Module.new do
        attrs.each do |attr|
          define_method(attr) do
            return super() if unredacted_access || new_record? || !info_request
            apply_masks_to(attr)
          end
        end
      end)
    end
  end

  # Returns the redacted value for attr. Dispatches to apply_masks_to_<attr>
  # if defined on the model, otherwise runs the plain text masking pipeline.
  def apply_masks_to(attr)
    unless respond_to?(attr)
      msg = "Unknown method :#{attr} given to #{self.class} redactable"
      raise ArgumentError, msg
    end

    try("apply_masks_to_#{attr}") ||
      apply_masks(unredacted.send(attr).to_s, 'text/plain')
  end

  def unredacted
    @unredacted ||= Redactable::Unredacted.new(self)
  end

  def unredacted_access
    @unredacted_access || false
  end
end
