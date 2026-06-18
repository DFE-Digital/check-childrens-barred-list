# Extends the GOV.UK service navigation so that nav items can be rendered as
# POST buttons (via button_to) instead of GET links.
#
# The govuk-components ServiceNavigationComponent only knows how to render
# link_to (GET). Sign out is state-changing, so it must not be a GET link:
# browser prefetch, link scanners and crawlers can trigger GET links and sign
# users out unexpectedly. POST items are passed via `post_navigation_items`
# and appended to the navigation list as button_to buttons styled to match the
# other links (see app/assets/stylesheets/main.scss).
class ServiceNavigationComponent < GovukComponent::ServiceNavigationComponent
  def initialize(post_navigation_items: [], **kwargs)
    @post_navigation_items = post_navigation_items
    super(**kwargs)
  end

  # Render the nav wrapper when there are POST items even if there are no GET
  # items (e.g. a signed-in user whose only nav item is "Sign out").
  def navigation
    return unless navigation_items? || @post_navigation_items.any?

    tag.nav(aria: { label: "Menu" }, class: "#{brand}-service-navigation__wrapper") do
      safe_join([menu_button, navigation_list])
    end
  end

  def navigation_list
    items = safe_join(navigation_items) + post_navigation_items_html

    tag.ul(items, id: navigation_id, class: "#{brand}-service-navigation__list")
  end

private

  def post_navigation_items_html
    safe_join(@post_navigation_items.map { |item| post_navigation_item(**item) })
  end

  def post_navigation_item(text:, href:)
    tag.li(class: "#{brand}-service-navigation__item") do
      button_to(text, href, class: "#{brand}-service-navigation__link")
    end
  end
end
