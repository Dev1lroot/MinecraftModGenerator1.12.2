import os, system, strutils

type
  MinecraftMod* = object
    name*: string
    modid*: string
    classpath*: string
    output*: string
    controller*: string
    varcontroller*: string

proc createItem*(modinfo: MinecraftMod, classprefix, creativetabclassname, classname, name: string)=
  var modid = modinfo.modid;
  var classpath = modinfo.classpath;
  echo "- предмет "&name&" добавлен"
  var code = """
package """ & classpath & classprefix & """;

import net.minecraftforge.fml.relauncher.SideOnly;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.common.registry.GameRegistry;
import net.minecraftforge.client.model.ModelLoader;
import net.minecraftforge.client.event.ModelRegistryEvent;

import net.minecraft.item.ItemStack;
import net.minecraft.item.Item;
import net.minecraft.client.renderer.block.model.ModelResourceLocation;
import net.minecraft.block.state.IBlockState;

import """ & modinfo.classpath & """.tabs.Tab""" & creativetabclassname & """;
import """ & modinfo.classpath & """.""" & modinfo.controller & """;

@""" & modinfo.controller & """.ModElement.Tag
public class """ & classname & """ extends """ & modinfo.controller & """.ModElement {
	@GameRegistry.ObjectHolder('""" & modinfo.modid & """:""" & name & """')
	public static final Item block = null;
	public """ & classname & """(""" & modinfo.controller & """ instance) {
		super(instance, 28);
	}

	@Override
	public void initElements() {
		elements.items.add(() -> new ItemCustom());
	}

	@SideOnly(Side.CLIENT)
	@Override
	public void registerModels(ModelRegistryEvent event) {
		ModelLoader.setCustomModelResourceLocation(block, 0, new ModelResourceLocation('""" & modinfo.modid & """:""" & name & """', 'inventory'));
	}
	public static class ItemCustom extends Item {
		public ItemCustom() {
			setMaxDamage(0);
			maxStackSize = 64;
			setUnlocalizedName('""" & name & """');
			setRegistryName('""" & name & """');
			setCreativeTab(Tab""" & creativetabclassname & """.tab);
		}

		@Override
		public int getItemEnchantability() {
			return 0;
		}

		@Override
		public int getMaxItemUseDuration(ItemStack itemstack) {
			return 0;
		}

		@Override
		public float getDestroySpeed(ItemStack par1ItemStack, IBlockState par2Block) {
			return 1F;
		}
	}
}"""
  code = code.replace("'","\"")
  var javadestination = getCurrentDir() & "\\" & modinfo.output & "\\main\\java\\" & classpath.replace(".","\\") & classprefix.replace(".","\\") & "\\"
  if not existsDir(javadestination):
    createDir(javadestination)
  writeFile(javadestination & classname & ".java", code)
  var resourceLocation = getCurrentDir() & "\\" & modinfo.output & "\\main\\resources\\assets\\" & modinfo.modid & "\\models\\item\\"
  if not existsDir(resourceLocation):
    createDir(resourceLocation)
  var jsonData = """
{
	"parent": "item/generated",
	"textures": {
		"layer0": """" & modinfo.modid & """:items/""" & name & """"
	}
}
"""
  writeFile(resourceLocation & name & ".json",jsonData)

proc createTab*(modinfo: MinecraftMod, classname, itemlogoclassname, itemlogoclasspath: string) =
  echo "Создание набора: "&classname
  var name = classname.toLower()
  var code = """
package """ & modinfo.classpath & """.tabs;

import net.minecraftforge.fml.relauncher.SideOnly;
import net.minecraftforge.fml.relauncher.Side;

import net.minecraft.item.ItemStack;
import net.minecraft.creativetab.CreativeTabs;

import """ & modinfo.classpath & """.""" & modinfo.controller & """;
import """ & modinfo.classpath & """.""" & itemlogoclasspath & """.""" & itemlogoclassname & """;

@""" & modinfo.controller & """.ModElement.Tag
public class Tab""" & classname & """ extends """ & modinfo.controller & """.ModElement {
	public Tab""" & classname & """(""" & modinfo.controller & """ instance) {
		super(instance, 23);
	}

	@Override
	public void initElements() {
		tab = new CreativeTabs("tab_""" & name & """") {
			@SideOnly(Side.CLIENT)
			@Override
			public ItemStack getTabIconItem() {
				return new ItemStack(""" & itemlogoclassname & """.block, (int) (1));
			}

			@SideOnly(Side.CLIENT)
			public boolean hasSearchBar() {
				return false;
			}
		};
	}
	public static CreativeTabs tab;
}
"""
  var javadestination = getCurrentDir() & "\\" & modinfo.output & "\\main\\java\\" & modinfo.classpath.replace(".","\\") & "\\tabs\\"
  if not existsDir(javadestination):
    createDir(javadestination)
  writeFile(javadestination & "Tab" & classname & ".java", code)

proc generateMainClass*(modinfo: MinecraftMod)=
  echo "Создание основного класса: " & modinfo.name
  var code = """
package """ & modinfo.classpath & """;

import net.minecraftforge.fml.relauncher.SideOnly;
import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.common.registry.GameRegistry;
import net.minecraftforge.fml.common.registry.EntityEntry;
import net.minecraftforge.fml.common.network.simpleimpl.SimpleNetworkWrapper;
import net.minecraftforge.fml.common.network.NetworkRegistry;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.event.FMLServerStartingEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.SidedProxy;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fluids.FluidRegistry;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.common.MinecraftForge;
import net.minecraftforge.client.event.ModelRegistryEvent;

import net.minecraft.world.biome.Biome;
import net.minecraft.potion.Potion;
import net.minecraft.item.Item;
import net.minecraft.block.Block;

import java.util.function.Supplier;
import """ & modinfo.classpath & """.proxies.IProxy""" & modinfo.name & """;

@Mod(modid = """ & modinfo.name & """.MODID, version = """ & modinfo.name & """.VERSION)
public class """ & modinfo.name & """ {
	public static final String MODID = """" & modinfo.modid & """";
	public static final String VERSION = "1.0.0";
	public static final SimpleNetworkWrapper PACKET_HANDLER = NetworkRegistry.INSTANCE.newSimpleChannel("""" & modinfo.modid & """:primary");
	@SidedProxy(clientSide = """" & modinfo.classpath & """.proxies.ClientProxy", serverSide = """" & modinfo.classpath & """.proxies.ServerProxy")
	public static IProxy""" & modinfo.name & """ proxy;
	@Mod.Instance(MODID)
	public static """ & modinfo.name & """ instance;
	public """ & modinfo.controller & """ elements = new """ & modinfo.controller & """();
	@Mod.EventHandler
	public void preInit(FMLPreInitializationEvent event) {
		MinecraftForge.EVENT_BUS.register(this);
		GameRegistry.registerWorldGenerator(elements, 5);
		GameRegistry.registerFuelHandler(elements);
		NetworkRegistry.INSTANCE.registerGuiHandler(this, new """ & modinfo.controller & """.GuiHandler());
		elements.preInit(event);
		MinecraftForge.EVENT_BUS.register(elements);
		elements.getElements().forEach(element -> element.preInit(event));
		proxy.preInit(event);
	}

	@Mod.EventHandler
	public void init(FMLInitializationEvent event) {
		elements.getElements().forEach(element -> element.init(event));
		proxy.init(event);
	}

	@Mod.EventHandler
	public void postInit(FMLPostInitializationEvent event) {
		proxy.postInit(event);
	}

	@Mod.EventHandler
	public void serverLoad(FMLServerStartingEvent event) {
		elements.getElements().forEach(element -> element.serverLoad(event));
		proxy.serverLoad(event);
	}

	@SubscribeEvent
	public void registerBlocks(RegistryEvent.Register<Block> event) {
		event.getRegistry().registerAll(elements.getBlocks().stream().map(Supplier::get).toArray(Block[]::new));
	}

	@SubscribeEvent
	public void registerItems(RegistryEvent.Register<Item> event) {
		event.getRegistry().registerAll(elements.getItems().stream().map(Supplier::get).toArray(Item[]::new));
	}

	@SubscribeEvent
	public void registerBiomes(RegistryEvent.Register<Biome> event) {
		event.getRegistry().registerAll(elements.getBiomes().stream().map(Supplier::get).toArray(Biome[]::new));
	}

	@SubscribeEvent
	public void registerEntities(RegistryEvent.Register<EntityEntry> event) {
		event.getRegistry().registerAll(elements.getEntities().stream().map(Supplier::get).toArray(EntityEntry[]::new));
	}

	@SubscribeEvent
	public void registerPotions(RegistryEvent.Register<Potion> event) {
		event.getRegistry().registerAll(elements.getPotions().stream().map(Supplier::get).toArray(Potion[]::new));
	}

	@SubscribeEvent
	public void registerSounds(RegistryEvent.Register<net.minecraft.util.SoundEvent> event) {
		elements.registerSounds(event);
	}

	@SubscribeEvent
	@SideOnly(Side.CLIENT)
	public void registerModels(ModelRegistryEvent event) {
		elements.getElements().forEach(element -> element.registerModels(event));
	}
	static {
		FluidRegistry.enableUniversalBucket();
	}
}"""
  var javadestination = getCurrentDir() & "\\" & modinfo.output & "\\main\\java\\" & modinfo.classpath.replace(".","\\") & "\\"
  if not existsDir(javadestination):
    createDir(javadestination)
  writeFile(javadestination & modinfo.name & ".java", code)

proc generateProxies*(modinfo: MinecraftMod) =
  var clientproxy = """
package """ & modinfo.classpath & """.proxies;

import net.minecraftforge.fml.common.event.FMLServerStartingEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.client.model.obj.OBJLoader;

public class ClientProxy implements IProxy""" & modinfo.name & """ {
	@Override
	public void init(FMLInitializationEvent event) {
	}

	@Override
	public void preInit(FMLPreInitializationEvent event) {
		OBJLoader.INSTANCE.addDomain("""" & modinfo.modid & """");
	}

	@Override
	public void postInit(FMLPostInitializationEvent event) {
	}

	@Override
	public void serverLoad(FMLServerStartingEvent event) {
	}
}"""
  var serverproxy = """
package """ & modinfo.classpath & """.proxies;

import net.minecraftforge.fml.common.event.FMLServerStartingEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;

public class ServerProxy implements IProxy""" & modinfo.name & """ {
	@Override
	public void preInit(FMLPreInitializationEvent event) {
	}

	@Override
	public void init(FMLInitializationEvent event) {
	}

	@Override
	public void postInit(FMLPostInitializationEvent event) {
	}

	@Override
	public void serverLoad(FMLServerStartingEvent event) {
	}
}"""
  var iproxy = """
package """ & modinfo.classpath & """.proxies;

import net.minecraftforge.fml.common.event.FMLServerStartingEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPostInitializationEvent;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;

public interface IProxy""" & modinfo.name & """ {
	void preInit(FMLPreInitializationEvent event);

	void init(FMLInitializationEvent event);

	void postInit(FMLPostInitializationEvent event);

	void serverLoad(FMLServerStartingEvent event);
}"""
  var javadestination = getCurrentDir() & "\\" & modinfo.output & "\\main\\java\\" & modinfo.classpath.replace(".","\\") & "\\proxies\\"
  if not existsDir(javadestination):
    createDir(javadestination)
  writeFile(javadestination & "IProxy" & modinfo.name & ".java", iproxy)
  writeFile(javadestination & "ServerProxy" & ".java", serverproxy)
  writeFile(javadestination & "ClientProxy" & ".java", clientproxy)

proc generateControllers*(modinfo: MinecraftMod) =
  var code = """
package """ & modinfo.classpath & """;

import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.common.registry.EntityEntry;
import net.minecraftforge.fml.common.network.simpleimpl.IMessageHandler;
import net.minecraftforge.fml.common.network.simpleimpl.IMessage;
import net.minecraftforge.fml.common.network.IGuiHandler;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.event.FMLServerStartingEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.discovery.ASMDataTable;
import net.minecraftforge.fml.common.IWorldGenerator;
import net.minecraftforge.fml.common.IFuelHandler;
import net.minecraftforge.event.RegistryEvent;
import net.minecraftforge.client.event.ModelRegistryEvent;

import net.minecraft.world.storage.WorldSavedData;
import net.minecraft.world.gen.IChunkGenerator;
import net.minecraft.world.chunk.IChunkProvider;
import net.minecraft.world.biome.Biome;
import net.minecraft.world.World;
import net.minecraft.util.ResourceLocation;
import net.minecraft.potion.Potion;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Item;
import net.minecraft.entity.player.EntityPlayerMP;
import net.minecraft.entity.player.EntityPlayer;
import net.minecraft.block.Block;

import java.util.function.Supplier;
import java.util.Random;
import java.util.Map;
import java.util.List;
import java.util.HashMap;
import java.util.Collections;
import java.util.ArrayList;

import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Retention;

public class """ & modinfo.controller & """ implements IFuelHandler, IWorldGenerator {
	public final List<ModElement> elements = new ArrayList<>();
	public final List<Supplier<Block>> blocks = new ArrayList<>();
	public final List<Supplier<Item>> items = new ArrayList<>();
	public final List<Supplier<Biome>> biomes = new ArrayList<>();
	public final List<Supplier<EntityEntry>> entities = new ArrayList<>();
	public final List<Supplier<Potion>> potions = new ArrayList<>();
	public static Map<ResourceLocation, net.minecraft.util.SoundEvent> sounds = new HashMap<>();
	public """ & modinfo.controller & """() {
	}

	public void preInit(FMLPreInitializationEvent event) {
		try {
			for (ASMDataTable.ASMData asmData : event.getAsmData().getAll(ModElement.Tag.class.getName())) {
				Class<?> clazz = Class.forName(asmData.getClassName());
				if (clazz.getSuperclass() == """ & modinfo.controller & """.ModElement.class)
					elements.add((""" & modinfo.controller & """.ModElement) clazz.getConstructor(this.getClass()).newInstance(this));
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		Collections.sort(elements);
		elements.forEach(""" & modinfo.controller & """.ModElement::initElements);
		this.addNetworkMessage(""" & modinfo.varcontroller & """.WorldSavedDataSyncMessageHandler.class, """ & modinfo.varcontroller & """.WorldSavedDataSyncMessage.class,
				Side.SERVER, Side.CLIENT);
	}

	public void registerSounds(RegistryEvent.Register<net.minecraft.util.SoundEvent> event) {
		for (Map.Entry<ResourceLocation, net.minecraft.util.SoundEvent> sound : sounds.entrySet())
			event.getRegistry().register(sound.getValue().setRegistryName(sound.getKey()));
	}

	@Override
	public void generate(Random random, int chunkX, int chunkZ, World world, IChunkGenerator cg, IChunkProvider cp) {
		elements.forEach(element -> element.generateWorld(random, chunkX * 16, chunkZ * 16, world, world.provider.getDimension(), cg, cp));
	}

	@Override
	public int getBurnTime(ItemStack fuel) {
		for (ModElement element : elements) {
			int ret = element.addFuel(fuel);
			if (ret != 0)
				return ret;
		}
		return 0;
	}

	@SubscribeEvent
	public void onPlayerLoggedIn(net.minecraftforge.fml.common.gameevent.PlayerEvent.PlayerLoggedInEvent event) {
		if (!event.player.world.isRemote) {
			WorldSavedData mapdata = """ & modinfo.varcontroller & """.MapVariables.get(event.player.world);
			WorldSavedData worlddata = """ & modinfo.varcontroller & """.WorldVariables.get(event.player.world);
			if (mapdata != null)
				""" & modinfo.name & """.PACKET_HANDLER.sendTo(new """ & modinfo.varcontroller & """.WorldSavedDataSyncMessage(0, mapdata), (EntityPlayerMP) event.player);
			if (worlddata != null)
				""" & modinfo.name & """.PACKET_HANDLER.sendTo(new """ & modinfo.varcontroller & """.WorldSavedDataSyncMessage(1, worlddata), (EntityPlayerMP) event.player);
		}
	}

	@SubscribeEvent
	public void onPlayerChangedDimension(net.minecraftforge.fml.common.gameevent.PlayerEvent.PlayerChangedDimensionEvent event) {
		if (!event.player.world.isRemote) {
			WorldSavedData worlddata = """ & modinfo.varcontroller & """.WorldVariables.get(event.player.world);
			if (worlddata != null)
				""" & modinfo.name & """.PACKET_HANDLER.sendTo(new """ & modinfo.varcontroller & """.WorldSavedDataSyncMessage(1, worlddata), (EntityPlayerMP) event.player);
		}
	}
	private int messageID = 0;
	public <T extends IMessage, V extends IMessage> void addNetworkMessage(Class<? extends IMessageHandler<T, V>> handler, Class<T> messageClass,
			Side... sides) {
		for (Side side : sides)
			""" & modinfo.name & """.PACKET_HANDLER.registerMessage(handler, messageClass, messageID, side);
		messageID++;
	}
	public static class GuiHandler implements IGuiHandler {
		@Override
		public Object getServerGuiElement(int id, EntityPlayer player, World world, int x, int y, int z) {
			return null;
		}

		@Override
		public Object getClientGuiElement(int id, EntityPlayer player, World world, int x, int y, int z) {
			return null;
		}
	}
	public List<ModElement> getElements() {
		return elements;
	}

	public List<Supplier<Block>> getBlocks() {
		return blocks;
	}

	public List<Supplier<Item>> getItems() {
		return items;
	}

	public List<Supplier<Biome>> getBiomes() {
		return biomes;
	}

	public List<Supplier<EntityEntry>> getEntities() {
		return entities;
	}

	public List<Supplier<Potion>> getPotions() {
		return potions;
	}
	public static class ModElement implements Comparable<ModElement> {
		@Retention(RetentionPolicy.RUNTIME)
		public @interface Tag {
		}
		protected final """ & modinfo.controller & """ elements;
		protected final int sortid;
		public ModElement(""" & modinfo.controller & """ elements, int sortid) {
			this.elements = elements;
			this.sortid = sortid;
		}

		public void initElements() {
		}

		public void init(FMLInitializationEvent event) {
		}

		public void preInit(FMLPreInitializationEvent event) {
		}

		public void generateWorld(Random random, int posX, int posZ, World world, int dimID, IChunkGenerator cg, IChunkProvider cp) {
		}

		public void serverLoad(FMLServerStartingEvent event) {
		}

		public void registerModels(ModelRegistryEvent event) {
		}

		public int addFuel(ItemStack fuel) {
			return 0;
		}

		@Override
		public int compareTo(ModElement other) {
			return this.sortid - other.sortid;
		}
	}
}"""
  var javadestination = getCurrentDir() & "\\" & modinfo.output & "\\main\\java\\" & modinfo.classpath.replace(".","\\") & "\\"
  if not existsDir(javadestination):
    createDir(javadestination)
  writeFile(javadestination & modinfo.controller & ".java", code)
  var vcon = """
package """ & modinfo.classpath & """;

import net.minecraftforge.fml.relauncher.Side;
import net.minecraftforge.fml.common.network.simpleimpl.MessageContext;
import net.minecraftforge.fml.common.network.simpleimpl.IMessageHandler;
import net.minecraftforge.fml.common.network.simpleimpl.IMessage;
import net.minecraftforge.fml.common.network.ByteBufUtils;

import net.minecraft.world.storage.WorldSavedData;
import net.minecraft.world.World;
import net.minecraft.nbt.NBTTagCompound;
import net.minecraft.client.Minecraft;

public class """ & modinfo.varcontroller & """ {
	public static class MapVariables extends WorldSavedData {
		public static final String DATA_NAME = """" & modinfo.modid & """_mapvars";
		public MapVariables() {
			super(DATA_NAME);
		}

		public MapVariables(String s) {
			super(s);
		}

		@Override
		public void readFromNBT(NBTTagCompound nbt) {
		}

		@Override
		public NBTTagCompound writeToNBT(NBTTagCompound nbt) {
			return nbt;
		}

		public void syncData(World world) {
			this.markDirty();
			if (world.isRemote) {
				""" & modinfo.name & """.PACKET_HANDLER.sendToServer(new WorldSavedDataSyncMessage(0, this));
			} else {
				""" & modinfo.name & """.PACKET_HANDLER.sendToAll(new WorldSavedDataSyncMessage(0, this));
			}
		}

		public static MapVariables get(World world) {
			MapVariables instance = (MapVariables) world.getMapStorage().getOrLoadData(MapVariables.class, DATA_NAME);
			if (instance == null) {
				instance = new MapVariables();
				world.getMapStorage().setData(DATA_NAME, instance);
			}
			return instance;
		}
	}

	public static class WorldVariables extends WorldSavedData {
		public static final String DATA_NAME = """" & modinfo.modid & """_worldvars";
		public WorldVariables() {
			super(DATA_NAME);
		}

		public WorldVariables(String s) {
			super(s);
		}

		@Override
		public void readFromNBT(NBTTagCompound nbt) {
		}

		@Override
		public NBTTagCompound writeToNBT(NBTTagCompound nbt) {
			return nbt;
		}

		public void syncData(World world) {
			this.markDirty();
			if (world.isRemote) {
				""" & modinfo.name & """.PACKET_HANDLER.sendToServer(new WorldSavedDataSyncMessage(1, this));
			} else {
				""" & modinfo.name & """.PACKET_HANDLER.sendToDimension(new WorldSavedDataSyncMessage(1, this), world.provider.getDimension());
			}
		}

		public static WorldVariables get(World world) {
			WorldVariables instance = (WorldVariables) world.getPerWorldStorage().getOrLoadData(WorldVariables.class, DATA_NAME);
			if (instance == null) {
				instance = new WorldVariables();
				world.getPerWorldStorage().setData(DATA_NAME, instance);
			}
			return instance;
		}
	}

	public static class WorldSavedDataSyncMessageHandler implements IMessageHandler<WorldSavedDataSyncMessage, IMessage> {
		@Override
		public IMessage onMessage(WorldSavedDataSyncMessage message, MessageContext context) {
			if (context.side == Side.SERVER)
				context.getServerHandler().player.getServerWorld()
						.addScheduledTask(() -> syncData(message, context, context.getServerHandler().player.world));
			else
				Minecraft.getMinecraft().addScheduledTask(() -> syncData(message, context, Minecraft.getMinecraft().player.world));
			return null;
		}

		private void syncData(WorldSavedDataSyncMessage message, MessageContext context, World world) {
			if (context.side == Side.SERVER) {
				message.data.markDirty();
				if (message.type == 0)
					""" & modinfo.name & """.PACKET_HANDLER.sendToAll(message);
				else
					""" & modinfo.name & """.PACKET_HANDLER.sendToDimension(message, world.provider.getDimension());
			}
			if (message.type == 0) {
				world.getMapStorage().setData(MapVariables.DATA_NAME, message.data);
			} else {
				world.getPerWorldStorage().setData(WorldVariables.DATA_NAME, message.data);
			}
		}
	}

	public static class WorldSavedDataSyncMessage implements IMessage {
		public int type;
		public WorldSavedData data;
		public WorldSavedDataSyncMessage() {
		}

		public WorldSavedDataSyncMessage(int type, WorldSavedData data) {
			this.type = type;
			this.data = data;
		}

		@Override
		public void toBytes(io.netty.buffer.ByteBuf buf) {
			buf.writeInt(this.type);
			ByteBufUtils.writeTag(buf, this.data.writeToNBT(new NBTTagCompound()));
		}

		@Override
		public void fromBytes(io.netty.buffer.ByteBuf buf) {
			this.type = buf.readInt();
			if (this.type == 0)
				this.data = new MapVariables();
			else
				this.data = new WorldVariables();
			this.data.readFromNBT(ByteBufUtils.readTag(buf));
		}
	}
}"""
  if not existsDir(javadestination):
    createDir(javadestination)
  writeFile(javadestination & modinfo.varcontroller & ".java", vcon)


proc deploy*(modinfo: MinecraftMod): MinecraftMod =
  var modout = modinfo
  modout.modid = modout.name.toLower();
  modout.controller = modout.name & "Elements"
  modout.varcontroller = modout.name & "Variables"
  modout.generateMainClass()
  modout.generateProxies()
  modout.generateControllers()
  return modout

proc createMaterial*(modinfo: MinecraftMod, classname: string) =
  var name = classname.toLower()
  echo "Создание материала: "&classname
  createItem(modinfo, ".materials."&name, "Materials", classname&"Rod", name&"_rod")
  createItem(modinfo, ".materials."&name, "Materials", classname&"Dust", name&"_dust")
  createItem(modinfo, ".materials."&name, "Materials", classname&"Coil", name&"_coil")
  createItem(modinfo, ".materials."&name, "Materials", classname&"Ingot", name&"_ingot")
