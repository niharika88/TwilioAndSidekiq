class MakeCallJob < ActiveJob::Base
  queue_as :default

  # Define our Twilio credentials as instance variables for later use
  @@twilio_sid = "ACe5574cc9a87fbf4f808c76893e17ee17"
  @@twilio_token = "cc1f525ed75e361077ea6e2588529a70"
  @@twilio_number = "+1 408-606-2853"

  def perform(to, url)
    client = Twilio::REST::Client.new @@twilio_sid, @@twilio_token
    # Connect an outbound call to the number submitted
    call = client.calls.create(
      :from => @@twilio_number,
      :to => to,
      :url => url # Fetch instructions from this URL when the call connects
    )
  end
end
