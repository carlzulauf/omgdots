module JsonCollection
  extend ActiveSupport::Concern

  included do
    delegate :count, to: :collection
  end

  attr_reader :collection

  def initialize(collection)
    @collection = collection
  end

  class_methods do
    def collection_of(*)

    end
  end
end
