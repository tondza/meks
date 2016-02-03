require 'rails_helper'

RSpec.describe Language, type: :model do
  it "should be adding one" do
    expect { Language.create(name: "Svenska") }.to change(Language, :count).by(+1)
  end

  describe 'validation' do
    it "should be valid" do
      expect(Language.create(name: "Svenska")).to be_valid
    end

    it "should require a name" do
      expect(Language.new).not_to be_valid
    end

    it "should be valid with a not too long name" do
      expect(Language.new name: "x" * 191).to be_valid
    end

    it "should not have a too long name" do
      expect(Language.new name: "x" * 192).not_to be_valid
    end

    it "should have a unique name" do
      Language.create(name: "Svenska")
      expect(Language.new name: "Svenska").not_to be_valid
    end

    it "... just checking transactional support" do
      expect(Language.count).to eq 0
    end
  end

  describe 'destroy' do
    it "should destroy a record" do
      expect { Language.create(name: "Svenska") }.to change(Language, :count).by(+1)
      expect { Language.where(name: "Svenska").first.destroy }.to change(Language, :count).by(-1)
    end
  end
end
