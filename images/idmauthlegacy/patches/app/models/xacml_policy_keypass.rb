class XacmlPolicyKeypass
  require 'rest_client'

  ErrorMessage = "Put XACML policy file to Keypass failed!" 
  #require 'xacml_file'
  # Create a new XACML Policy
  # The application has available the following methods
  #
  #   application.roles #=> list of roles
  #
  #   role = application.roles.first
  #
  #   role.permissions #=> list of permissions per role
  #

  class << self
    def save(application)
      new(application)
    end
  end

  def initialize(application)

    puts '*' * 30
    puts "Application.name = "+application.name
    roles = application.roles

    roles.each do |role|
      create_XACML(application, role)
    end
  end

  def create_XACML(application, role)

    xacml = XacmlFileKeypass.new

    xml = xacml.create_policy_keypass(application, role)

    ##print xml file
#    puts xml.to_xml

    put_request_keypass(application, xml, role)

  end

  def put_request_keypass(application, xml, role)
    client = RestClient::Resource.new(
      FiWareIdm::Keypass.url+role.id.to_s,
      :headers => {'fiware-Service' => application.id.to_s})

      response = client.post(
      xml.to_xml,
      :content_type => "application/xml",
      :accept => "application/xml")
  end

end
