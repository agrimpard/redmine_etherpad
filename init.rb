#
# vendor/plugins/redmine_etherpad/init.rb
#

require 'redmine'
require 'uri'


def hash_to_querystring(hash)
  hash.keys.inject('') do |query_string, key|
    query_string << '&' unless key == hash.keys.first
    query_string << "#{URI.encode_www_form_component(key.to_s)}=#{URI.encode_www_form_component(hash[key].to_s)}"
  end
end

Redmine::Plugin.register :redmine_etherpad do
  name 'Redmine Etherpad plugin'
  author 'Aurélien Grimpard'
  description 'Embed etherpad-lite pads in redmine wikis.'
  version '0.0.3'
  url 'https://github.com/agrimpard/redmine_etherpad'
  author_url 'https://github.com/agrimpard'

  Redmine::WikiFormatting::Macros.register do
    desc "Embed etherpad"
    macro :etherpad do |obj, args|
      conf = Redmine::Configuration['etherpad']
      unless conf and conf['host'] 
        raise "Please define etherpad parameters in configuration.yml."
      end

      # Defaults from configuration.
      controls = {
        'showControls' => conf.fetch('showControls', true),
        'showChat' => conf.fetch('showChat', true),
        'showLineNumbers' => conf.fetch('showLineNumbers', false),
        'useMonospaceFont' => conf.fetch('useMonospaceFont', false),
        'noColors' => conf.fetch('noColors', false),
		'style' => conf.fetch('style', 'width:640px;height:480px')
      }

      # Override defaults with given arguments.
      padname, *params = args
      for param in params
        key, val = param.strip().split("=")
        unless controls.has_key?(key)
          raise "#{key} not a recognized parameter."
        else
          controls[key] = val
        end
      end

      # Set current user name.
      if User.current
        controls['userName'] = User.current.name
      elsif conf.fetch('loginRequired', true)
        return "TODO: embed read-only."
      end

      style = controls.delete('style')

      # add project name before padname and hexencode the result
      projectname = @project.identifier
      realname = Digest::SHA1.hexdigest(projectname + padname)
      
      return CGI::unescapeHTML("<iframe src='#{conf['host']}/p/#{URI.encode_www_form_component(realname)}?#{hash_to_querystring(controls)}' style='#{style}'></iframe>").html_safe
    end
  end
end
