module Otis
  class Badge
    def initialize(tag, css_class)
      @tag = tag
      @css_class = css_class
    end

    def label_text
      I18n.t tag
    end

    def label_span
      "<span class='label #{css_class}'>#{label_text}</span>".html_safe
    end

    alias_method :to_html, :label_span

    private

    attr_reader :css_class, :tag
  end
end
