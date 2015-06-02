require_dependency 'fi_ware_idm/keypass'

FiWareIdm::Keypass.setup do |config|
  # Enable Keypass integration
  config.enable = true

  # Url of the Keypass endpoint
  config.url = "http://localhost:7070/pap/v1/subject/" 
end
