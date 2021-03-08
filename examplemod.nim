import modmaker

var zaebcraft = MinecraftMod(
  name: "Zaebcraft",
  classpath: "no.dev1lroot.zaebcraft", 
  output: "zaebgenerator"
)

zaebcraft = zaebcraft.deploy()
# Таб Материалов
zaebcraft.createTab("Materials","CopperIngot","materials.copper")
# Материалы
zaebcraft.createMaterial("Zinc")
zaebcraft.createMaterial("Tin")
zaebcraft.createMaterial("Copper")
zaebcraft.createMaterial("Nickel")
zaebcraft.createMaterial("Nichrome")
zaebcraft.createMaterial("Titanium")
zaebcraft.createMaterial("beryllium")
zaebcraft.createMaterial("Cobalt")
zaebcraft.createMaterial("Alumel")
zaebcraft.createMaterial("Aluminium")
zaebcraft.createMaterial("Chrome")
