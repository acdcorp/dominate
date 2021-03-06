require 'tilt/template'

module Dominate
  module HTML
    extend self

    IMAGE_TYPES  = %w(png gif jpg jpeg)
    FONT_TYPES   = %w(eot woff ttf svg)
    STATIC_TYPES = %w(html js css map)
    VIEW_TYPES   = %w(html slim haml erb md markdown mkd mab)


    def file file, instance = false, config = {}
      c    = (Dominate.config.to_h.merge config).to_deep_ostruct
      path = "#{c.view_path}/#{file}"
      html = load_file path, c, instance

      if c.parse_dom
        unless dom_cache = _dom_cache[path]
          dom_cache = (_dom_cache[path] = Dom.new(html, instance, config))
        end

        dom = dom_cache.dup

        if File.file? path + '.dom'
          dom = Instance.new(instance, c).instance_eval File.read(path + '.dom')
        end

        dom
      else
        html
      end
    end

    def load_file path, c = {}, instance = self
      cache = _cache.fetch(path) {
        template = false

        ext = path[/\.[^.]*$/][1..-1]

        if ext && File.file?(path)
          if STATIC_TYPES.include? ext
            template = Tilt::PlainTemplate.new nil, 1, outvar: '@_output', default_encoding: 'UTF-8' do |t|
              File.read(path)
            end
          elsif FONT_TYPES.include?(ext) || IMAGE_TYPES.include?(ext)
            template = File.read path
          else
            template = Tilt.new path, 1, outvar: '@_output'
          end
        else
          VIEW_TYPES.each do |type|
            f = "#{path}.#{type}"

            if File.file? f
              template = Tilt.new f, 1, outvar: '@_output'
              break
            end
          end
        end

        unless template
          raise Dominate::NoFileFound,
            "Could't find file: #{path} with any of these extensions: #{VIEW_TYPES.join(', ')}."
        end

        template
      }

      if defined? cache.render
        cache.render instance, c.to_h
      else
        cache.to_s
      end
    end

    private

    # @private Used internally by #render to cache the
    #          ::Tilt templates.
    def _cache
      Thread.current[:_cache] ||= ::Tilt::Cache.new
    end

    def _dom_cache
      Thread.current[:_dom_cache] ||= {}
    end
  end
end
