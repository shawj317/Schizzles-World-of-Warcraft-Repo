CUSTOM_SOURCES = {
 'szfloor': 'max(VendorSell * 1.25, 1c)',
 'szseen': 'first(AtrValue, DBMinBuyout, DBRegionMarketAvg)',
 'szvalue': 'first(szseen, Crafting, VendorSell * 4)',
 'szmat': 'first(AtrValue, DBMinBuyout, VendorBuy, VendorSell * 4)',
 'szcraft': 'first(Crafting, szvalue)',
 'szmin': 'max(szfloor, Crafting * 1.1)',
 'szmax': 'max(szvalue * 2, szfloor * 3)',
 'szsnipe': 'max(szvalue * 0.6, szfloor)',
}
SETUP_LUA = r'''
local CS=ADDON.LibTSMTypes:Include("CustomString")
local tick=0; CS.SetFrameTimeFunc(function() tick=tick+1 return tick end)
for _,src in ipairs({"AtrValue","DBMinBuyout","DBRegionMarketAvg","VendorSell","VendorBuy","Crafting","DBMarket"}) do
  local k=strlower(src)
  CS.RegisterSource("Test", src, src, function(itemString) local v=VALS and VALS[itemString]; return v and v[k] end, CS.SOURCE_TYPE.PRICE_DB)
end
CSX=CS
'''
