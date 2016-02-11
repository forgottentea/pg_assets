require 'test_helper'

describe PgAssets::Services::PGAssetManager do
  before do
    load_asset :view1
    load_asset :view2
    load_asset :matview1
    load_asset :matview2
    load_asset :function1
    load_asset :function2
    load_asset :trigger1
    load_asset :trigger2
    load_asset :constraint_multiple
  end

  describe ".views" do
    it "lists the views" do
      PgAssets::Services::PGAssetManager.views.size.must_equal 2
      PgAssets::Services::PGAssetManager.views.first.viewname.must_equal 'view1'
      PgAssets::Services::PGAssetManager.views.second.viewname.must_equal 'view2'
    end
  end

  describe ".matviews" do
    it "lists the materialized views" do
      PgAssets::Services::PGAssetManager.matviews.size.must_equal 2
      PgAssets::Services::PGAssetManager.matviews.first.matviewname.must_equal 'matview1'
      PgAssets::Services::PGAssetManager.matviews.second.matviewname.must_equal 'matview2'
    end
  end

  describe ".functions" do
    it "lists the functions" do
      PgAssets::Services::PGAssetManager.functions.size.must_equal 4  # each trigger has functions
      PgAssets::Services::PGAssetManager.functions.first.proname.must_equal 'function1'
      PgAssets::Services::PGAssetManager.functions.second.proname.must_equal 'function2'
      PgAssets::Services::PGAssetManager.functions.last.proname.must_equal 'womp2'
    end
  end

  describe ".triggers" do
    it "lists the triggers" do
      PgAssets::Services::PGAssetManager.triggers.size.must_equal 2
      PgAssets::Services::PGAssetManager.triggers.first.tgname.must_equal 'trigger1'
      PgAssets::Services::PGAssetManager.triggers.second.tgname.must_equal 'trigger2'
    end
  end

  describe ".constraints" do
    it "lists the constraints" do
      PgAssets::Services::PGAssetManager.constraints.size.must_equal 3
      PgAssets::Services::PGAssetManager.constraints.first.conname.must_equal 'table_with_multiple_constraint_test2_key'
      PgAssets::Services::PGAssetManager.constraints.second.conname.must_equal 'table_with_multiple_constraint_test_check'
      PgAssets::Services::PGAssetManager.constraints.last.conname.must_equal 'table_with_multiple_constraint_test_check1'
    end
  end

  describe ".assets_dump" do
    it "creates an asset dump" do
      regexes = [
        /BRO/,
        /CREATE OR REPLACE VIEW/i,
        /CREATE OR REPLACE FUNCTION/i,
        /DROP TRIGGER IF EXISTS/i,
        /CREATE TRIGGER/i,
        /public.womp2/,
        /view1/,
        /view2/,
        /function1/,
        /function2/,
        /trigger1/,
        /trigger2/
      ]
      assets_dump = PgAssets::Services::PGAssetManager.assets_dump
      regexes.each do |regex|
        assets_dump.must_match regex
      end
    end

    it "orders things properly" do
      assets_dump = PgAssets::Services::PGAssetManager.assets_dump
      view_index = assets_dump.index('CREATE OR REPLACE VIEW')
      function_index = assets_dump.index('CREATE OR REPLACE FUNCTION')
      trigger_index = assets_dump.index('CREATE TRIGGER')

      assert_operator view_index, :<, function_index
      assert_operator function_index, :<, trigger_index
    end
  end

  describe ".assets_load" do
    before do
      @assets = PgAssets::Services::PGAssetManager.assets_dump
      PgAssets::Services::PGAssetManager.views.each { |v| v.remove }
      PgAssets::Services::PGAssetManager.matviews.each { |v| v.remove }
      PgAssets::Services::PGAssetManager.triggers.each { |t| t.remove }
      PgAssets::Services::PGAssetManager.functions.each { |f| f.remove }
      PgAssets::Services::PGAssetManager.constraints.each { |f| f.remove }
    end

    it "loads the assets" do
      PgAssets::Services::PGAssetManager.views.size.must_equal 0
      PgAssets::Services::PGAssetManager.matviews.size.must_equal 0
      PgAssets::Services::PGAssetManager.functions.size.must_equal 0
      PgAssets::Services::PGAssetManager.triggers.size.must_equal 0
      PgAssets::Services::PGAssetManager.constraints.size.must_equal 0

      PgAssets::Services::PGAssetManager.assets_load @assets

      PgAssets::Services::PGAssetManager.views.size.must_equal 2
      PgAssets::Services::PGAssetManager.matviews.size.must_equal 2
      PgAssets::Services::PGAssetManager.functions.size.must_equal 4
      PgAssets::Services::PGAssetManager.triggers.size.must_equal 2
      PgAssets::Services::PGAssetManager.constraints.size.must_equal 3
    end

    it "does not load assets twice if the rake task is run twice" do
      PgAssets::Services::PGAssetManager.views.size.must_equal 0
      PgAssets::Services::PGAssetManager.matviews.size.must_equal 0
      PgAssets::Services::PGAssetManager.functions.size.must_equal 0
      PgAssets::Services::PGAssetManager.triggers.size.must_equal 0
      PgAssets::Services::PGAssetManager.constraints.size.must_equal 0

      PgAssets::Services::PGAssetManager.assets_load @assets

      PgAssets::Services::PGAssetManager.views.size.must_equal 2
      PgAssets::Services::PGAssetManager.matviews.size.must_equal 2
      PgAssets::Services::PGAssetManager.functions.size.must_equal 4
      PgAssets::Services::PGAssetManager.triggers.size.must_equal 2
      PgAssets::Services::PGAssetManager.constraints.size.must_equal 3

      PgAssets::Services::PGAssetManager.assets_load @assets

      PgAssets::Services::PGAssetManager.views.size.must_equal 2
      PgAssets::Services::PGAssetManager.matviews.size.must_equal 2
      PgAssets::Services::PGAssetManager.functions.size.must_equal 4
      PgAssets::Services::PGAssetManager.triggers.size.must_equal 2
      PgAssets::Services::PGAssetManager.constraints.size.must_equal 3

      PgAssets::Services::PGAssetManager.assets_dump.must_equal @assets
    end
  end
end
