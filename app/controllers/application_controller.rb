class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper_method :present

  def present(model, presenter: nil, name: nil, type: :html, context: nil)
    presenter ||= "#{name&.to_s.titleize || model.model_name}#{type.to_s.titleize}Presenter".constantize
    presenter.new(model, view_context: context || view_context).tap { |i| yield(i) if block_given? }
  end
end
