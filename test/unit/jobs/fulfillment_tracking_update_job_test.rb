require 'test_helper'

class FulfillmentTrackingUpdateJobTest < ActiveSupport::TestCase
  def setup
    stub_shop_callbacks
    @shop = shops(:david)
  end

  test "Perform makes tracking requests and updates fulfillment" do
    fulfillment = create(:fulfillment, expected_delivery_date: DateTime.now + 1.week, shop: @shop, line_items: [create(:line_item)])
    active_order_ids = [fulfillment.shipwire_order_id]
    response = {fulfillment.shipwire_order_id => {returned: "Yes"}}
    ShipwireApp::Application.config.shipwire_fulfillment_service_class.any_instance.expects(:fetch_shop_tracking_info).with(active_order_ids).returns(response)

    FulfillmentTrackingUpdateJob.perform
    assert_equal "Yes", fulfillment.reload.returned
  end

  test "Perform only updates recent fulfillments" do
    fulfillment1 = create(:fulfillment, expected_delivery_date: DateTime.now + 1.week, shop: @shop, line_items: [create(:line_item)])
    fulfillment2 = create(:fulfillment, expected_delivery_date: DateTime.now - 2.months, shop: @shop, line_items: [create(:line_item)])

    active_order_ids = [fulfillment1.shipwire_order_id]
    ShipwireApp::Application.config.shipwire_fulfillment_service_class.any_instance.expects(:fetch_shop_tracking_info).with(active_order_ids).returns({})

    FulfillmentTrackingUpdateJob.perform
  end
end