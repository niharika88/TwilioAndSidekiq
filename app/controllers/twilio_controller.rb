require 'twilio-ruby'
require 'responders'

class TwilioController < ApplicationController
  # Before we allow the incoming request to connect, verify
  # that it is a Twilio request
  skip_before_filter  :verify_authenticity_token
  before_filter :authenticate_twilio_request, :only => [
    :connect
  ]

  # Define our Twilio credentials as instance variables for later use
  @@twilio_sid = "ACe5574cc9a87fbf4f808c76893e17ee17"
  @@twilio_token = "cc1f525ed75e361077ea6e2588529a70"
  @@twilio_number = "+1 408-606-2853"

  # Render home page
  def index
  	render 'index'
  end

  # Hande a POST from our web form and connect a call via REST API
  def call
    debugger
    contact = Contact.new
    contact.phone = params[:phone]

    # Validate contact
    if contact.valid?
      #using sidekiq and sctive job
 # MakeCallJob.perform_later(contact.phone, connect_url)
      @client = Twilio::REST::Client.new @@twilio_sid, @@twilio_token
      # Connect an outbound call to the number submitted
      @call = @client.account.calls.create(
        :from => @@twilio_number,
        :to => contact.phone,
        :url => "#{root_url}connect" # Fetch instructions from this URL when the call connects
      )

      # Lets respond to the ajax call with some positive reinforcement
      @msg = { :message => 'Phone call incoming! Please pickup', :status => 'ok' }

    else

      # Oops there was an error, lets return the validation errors
      @msg = { :message => contact.errors.full_messages, :status => 'ok' }
    end
    render json: @msg.to_json

  end

  # This URL contains instructions for the call that is connected with a lead
  # that is using the web form.  These instructions are used either for a
  # direct call to our Twilio number (the mobile use case) or
  def connect
    # Our response to this request will be an XML document in the "TwiML"
    # format. Our Ruby library provides a helper for generating one
    # of these documents
    response = Twilio::TwiML::Response.new do |r|
      r.Say 'If this were a real click to call implementation, you would be connected to an agent at this point.', :voice => 'alice'
    end
    render text: response.text
  end


  # Authenticate that all requests to our public-facing TwiML pages are
  # coming from Twilio. Adapted from the example at
  # http://twilio-ruby.readthedocs.org/en/latest/usage/validation.html
  # Read more on Twilio Security at https://www.twilio.com/docs/security
  private
  def authenticate_twilio_request
    twilio_signature = request.headers['HTTP_X_TWILIO_SIGNATURE']

    # Helper from twilio-ruby to validate requests.
    @validator = Twilio::Util::RequestValidator.new(@@twilio_token)

    # the POST variables attached to the request (eg "From", "To")
    # Twilio requests only accept lowercase letters. So scrub here:
    post_vars = params.reject {|k, v| k.downcase == k}

    is_twilio_req = @validator.validate(request.url, post_vars, twilio_signature)

    unless is_twilio_req
      render :xml => (Twilio::TwiML::Response.new {|r| r.Hangup}).text, :status => :unauthorized
      false
    end
  end

end
