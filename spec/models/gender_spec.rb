require 'rails_helper'

RSpec.describe Gender, type: :model do
  it "should be adding one" do
    expect { create(:gender) }.to change(Gender, :count).by(+1)
  end

  describe 'validation' do
    it "should be valid" do
      expect(build(:gender)).to be_valid
    end

    it "should require a name" do
      expect(build(:gender, name: "")).not_to be_valid
    end

    it "should be valid with a not too long name" do
      expect(build(:gender, name: "x" * 191)).to be_valid
    end

    it "should not have a too long name" do
      expect(build(:gender, name: "x" * 192)).not_to be_valid
    end

    it "should have a unique name" do
      create(:gender, name: "Kvinna")
      expect(build(:gender, name: "Kvinna")).not_to be_valid
    end

    it "... just checking transactional support" do
      expect(Gender.count).to eq 0
    end
  end

  describe 'destroy' do
    it "should destroy a record" do
      expect { create(:gender) }.to change(Gender, :count).by(+1)
      expect { Gender.first.destroy }.to change(Gender, :count).by(-1)
    end

    it "should delete a gender reference for a refugee" do
      gender = create(:gender)
      refugee = create(:refugee, gender: gender)
      expect(refugee.gender).to be_present
      gender.destroy
      refugee.reload
      expect(refugee.gender).not_to be_present
    end
  end
end
