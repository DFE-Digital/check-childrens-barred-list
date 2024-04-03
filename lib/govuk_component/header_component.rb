class GovukComponent::HeaderComponent
  class GovukComponent::HeaderComponent::NavigationItem
    attr_reader :post, :params

    def initialize(text:, href: nil, post: false, options: {}, active: nil, classes: [], html_attributes: {})
      @text            = text
      @href            = href
      @options         = options
      @active_override = active
      @post            = post

      if button_to?
        query = URI(@href).query
        @params = query.present? ? Hash[URI.decode_www_form(query)] : {}
      end

      super(classes:, html_attributes:)
    end

    def button_to?
      post == true
    end

    def call
      tag.li(**html_attributes) do
        if button_to?
          button_to(text, href, params:, class: "#{brand}-header__link", **options)
        elsif link?
          link_to(text, href, class: "#{brand}-header__link", **options)
        else
          text
        end
      end
    end
  end
end
