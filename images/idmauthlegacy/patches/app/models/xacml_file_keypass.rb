class XacmlFileKeypass

  StrSchemaLocation = 'urn:oasis:names:tc:xacml:3.0:core:schema:wd-17 http://docs.oasis-open.org/xacml/3.0/xacml-core-v3-schema-wd-17.xsd'
  StrPolicyCombiningAlgDenyUnlessPermit = "urn:oasis:names:tc:xacml:3.0:rule-combining-algorithm:deny-unless-permit" 
  Strxmlns2 = "urn:oasis:names:tc:xacml:3.0:core:schema:wd-17" 
  StrSchemaInstance = "http://www.w3.org/2001/XMLSchema-instance" 
  StrMatchId = "urn:oasis:names:tc:xacml:1.0:function:string-regexp-match" 
  StrCategoryResource = "urn:oasis:names:tc:xacml:3.0:attribute-category:resource" 
  StrFuncOneAndOnly = "urn:oasis:names:tc:xacml:1.0:function:string-one-and-only" 
  StrAttrCategory = "urn:oasis:names:tc:xacml:3.0:attribute-category:action" 
  StrDataType = "http://www.w3.org/2001/XMLSchema#string" 
  StrResourceId = "urn:oasis:names:tc:xacml:1.0:resource:resource-id" 
  StrFuncStrEqual ='urn:oasis:names:tc:xacml:1.0:function:string-equal'
  StrActionId = "urn:oasis:names:tc:xacml:1.0:action:action-id" 

  def create_policy_keypass(application, role)
    #create policy node
    builder = Nokogiri::XML::Builder.new do |xml|

      xml.Policy('xsi:schemaLocation' => StrSchemaLocation, :PolicyId => role.id, :RuleCombiningAlgId => StrPolicyCombiningAlgDenyUnlessPermit, :Version => "1.0",
        'xmlns' => Strxmlns2, 'xmlns:xsi' => StrSchemaInstance){
        xml.Description 'Role permissions policy file for '+role.name
        xml.Target{
          xml.AnyOf{
            xml.AllOf{
              xml.Match(:MatchId => StrMatchId) {
                xml.AttributeValue('frn:contextbroker:'+application.id.to_s+':.*', :DataType => StrDataType)
                xml.AttributeDesignator(:DataType => StrDataType, :AttributeId => StrResourceId, :MustBePresent => "true",
                  :Category => StrCategoryResource)
              }
            }
          }
        }
        role.permissions.each do |permission|
          action = permission.action
          object = permission.object
          xml_policy = permission.xml

          if object == nil
            object="null" 
          end

          if xml_policy == nil || xml_policy.blank?
            create_rule_keypass(xml, role, action, object)
          else
            xml << xml_policy
          end
        end
      }
    end

  end

  def create_rule_keypass(xml, role, action, object )
    #create all the rules
    xml.Rule(:RuleId => "role_#{ role.id }_can_#{ action.to_s.gsub(/\s/, '') }_#{ object.to_s.gsub(/\s/, '') }", :Effect =>'Permit'){
      xml.Description(role.name + ' can ' + action.to_s + ' ' + object.to_s)
      xml.Condition{
        xml.Apply(:FunctionId => StrFuncStrEqual){
          xml.Apply(:FunctionId => StrFuncOneAndOnly){
            xml.AttributeDesignator(:AttributeId => StrActionId, :DataType => StrDataType, :MustBePresent => "true", :Category => StrAttrCategory)
          }
          xml.AttributeValue(object, :DataType => StrDataType)
        }
      }
    }
  end

end
