module ApplicationHelper
  def support_interface?
    request.path.start_with?("/support")
  end
end
