module Otis
  class Badge
    def initialize(tag, css_class, **args)
      @tag = tag
      @css_class = css_class
      @args = args
    end

    def label_text
      I18n.t tag, **@args
    end

    def label_span
      "<span class='badge #{css_class}'>#{label_text}</span>".html_safe
    end

    alias_method :to_html, :label_span

    private

    attr_reader :css_class, :tag
  end
end
