function init()
  -- add manually your shaders from /data/shaders

  -- map shaders
  g_shaders.createShader("map_default", "/shaders/map_default_vertex", "/shaders/map_default_fragment")  

  g_shaders.createShader("map_rainbow", "/shaders/map_rainbow_vertex", "/shaders/map_rainbow_fragment")
  g_shaders.addTexture("map_rainbow", "/images/shaders/rainbow.png")

  -- use modules.game_interface.gameMapPanel:setShader("map_rainbow") to set shader

  -- outfit shaders
  g_shaders.createOutfitShader("outfit_default", "/shaders/outfit_default_vertex", "/shaders/outfit_default_fragment")

  g_shaders.createOutfitShader("Rainbow", "/shaders/outfit_rainbow_vertex", "/shaders/outfit_rainbow_fragment")
  g_shaders.addTexture("Rainbow", "/images/shaders/rainbow.png")

  -- you can use creature:setOutfitShader("outfit_rainbow") to set shader

  
  g_shaders.createOutfitShader("K2", "/shaders/outfit_k2_vertex", "/shaders/outfit_k2_fragment")
  g_shaders.addTexture("K2", "/images/shaders/K2.png")

  g_shaders.createOutfitShader("test", "/shaders/outfit_default_vertex", "/shaders/outfit_test_fragment")
  g_shaders.createOutfitShader("crazy", "/shaders/outfit_default_vertex", "/shaders/outfit_crazy_fragment")
  g_shaders.createOutfitShader("novo", "/shaders/outfit_default_vertex", "/shaders/outfit_NOVO_fragment")
  g_shaders.createOutfitShader("test2", "/shaders/outfit_default_vertex", "/shaders/outfit_TEST2_fragment")
  g_shaders.createOutfitShader("party", "/shaders/outfit_default_vertex", "/shaders/outfit_party_fragment")
  g_shaders.createOutfitShader("noise", "/shaders/outfit_default_vertex", "/shaders/outfit_noise_fragment")
  g_shaders.createOutfitShader("jely", "/shaders/outfit_default_vertex", "/shaders/outfit_jely_fragment")
  g_shaders.createOutfitShader("ghost", "/shaders/outfit_default_vertex", "/shaders/outfit_ghost_fragment")

end

function terminate()
end


