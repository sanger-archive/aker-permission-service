JSONAPI.configure do |config|
  config.exception_class_whitelist = [CanCan::AccessDenied]
end
