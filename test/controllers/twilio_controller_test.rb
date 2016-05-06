class TwilioControllerTest < ActionController::TestCase
include ActiveJob::TestHelper
  test "should initiate a call with a real phone number" do
    to_number = '12066505813'
    assert_enqueued_with job: MakeCallJob, args: [to_number, connect_url] do
      post :call, :phone => to_number, :format => 'json'
      assert_response :ok
      json = JSON.parse(response.body)
      assert_equal 'ok', json['status']
      assert_equal 'Phone call incoming!', json['message']
      assert_enqueued_jobs 1
    end
  end
end
