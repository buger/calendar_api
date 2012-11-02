describe Customer do
  let!(:customer1) { create(:customer) }
  let!(:customer2) { create(:customer) }
  let(:calendar1) { attributes_for(:calendar) }

  it "has many calendars" do
    calendar = customer1.calendars.create!(calendar1.slice(:title))
    calendar.reload
    Calendar.count.should == 1
    customer1.calendars.should == [calendar]
    customer2.calendars.should == []
  end
end

