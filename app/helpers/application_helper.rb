module ApplicationHelper


  def markdown(str)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    markdown.render(str).html_safe
  end
end
