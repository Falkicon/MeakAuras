-- WOW008 test
C_SettingsUtil.NotifySettingsLoaded()

-- WOW007 test (5 args instead of 7)
Settings.RegisterAddOnSetting(category, "mySetting", MyAddon.db.profile, type(true), "My Setting Name")

