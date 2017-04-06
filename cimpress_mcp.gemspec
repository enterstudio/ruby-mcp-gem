Gem::Specification.new do |s|
  s.name        = 'cimpress_mcp'
  s.version     = '0.0.4'
  s.date        = '2017-01-06'
  s.summary     = "Cimpress MCP"
  s.description = "Client for the Cimpress mass customization platform"
  s.authors     = ["Cimpress"]
  s.email       = 'rubygem@cimpress.io'
  s.files       = Dir["lib/**/*"]
  s.homepage    =
    'https://github.com/Cimpress-MCP/ruby-mcp-gem'
  s.license       = 'Apache-2.0'

  s.executables << 'mcpcli'

  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'prawn'
  s.add_runtime_dependency 'jwt'

  s.add_development_dependency 'airborne'

end
