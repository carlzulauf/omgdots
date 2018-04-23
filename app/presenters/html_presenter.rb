class HtmlPresenter < SimpleDelegator
  def initialize(record, view_context)
    @view = view_context
    super(record)
  end

  def h
    @view
  end
end
