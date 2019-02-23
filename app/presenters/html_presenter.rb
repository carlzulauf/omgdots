class HtmlPresenter < SimpleDelegator
  def initialize(record, **options)
    @options = options
    super(record)
  end

  def object
    __getobj__
  end

  def h
    @options.fetch(:view_context) do
      ActionController::Base.view_context_class.new
    end
  end
end
