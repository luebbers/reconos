package de.upb.reconos.layout;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.util.Vector;

import de.upb.reconos.fpga.DeviceDB;
import de.upb.reconos.fpga.DeviceInfo;
import de.upb.reconos.layout.editor.Range;
import de.upb.reconos.parser.ConfigNode;
import de.upb.reconos.parser.ConfigNodeType;
import de.upb.reconos.parser.ConfigParser;

public class Layout {
	private Vector<Slot> slots;
	private DeviceInfo fpgaInfo;
	
	public Layout(DeviceInfo fpga){
		slots = new Vector<Slot>();
		this.fpgaInfo = fpga;
	}
	
	public DeviceInfo getFPGAInfo(){
		return fpgaInfo;
	}
	
	public Slot createSlot(int x, int y, String name){
		Slot s = new Slot(x,y,name,fpgaInfo);
		slots.add(s);
		return s;
	}
	
	public boolean isValidSlot(Slot slot){
		Range range = slot.getSliceRange();
		for(Slot s : slots){
			if(s == slot) continue;
			Range r = s.getSliceRange();
			if(r.getXMax() >= range.getXMin()
			&& r.getXMin() <= range.getXMax()) return false;
		}
		return true;
	}
	
	public boolean isValidBusMacro(BusMacro bm){
		for(Slot s : slots){
			for(BusMacro b : s.getBusMacros()){
				if(b == bm) continue;
				if(b.getRangeA().intersects(bm.getRangeA())) return false;
				if(b.getRangeA().intersects(bm.getRangeB())) return false;
				if(b.getRangeB().intersects(bm.getRangeA())) return false;
				if(b.getRangeB().intersects(bm.getRangeB())) return false;
			}
			if(s != bm.getSlot()){
				if(bm.getRangeA().intersects(s.getSliceRange())) return false;
				if(bm.getRangeB().intersects(s.getSliceRange())) return false;
			}
		}
		return fpgaInfo.isValidBusMacro(bm);
	}
	
	public void removeSlot(Slot s){
		slots.remove(s);
	}
	
	public Vector<Slot> getSlots(){
		return slots;
	}
	
	public void write(File fout) throws IOException{
		
		PrintStream ps = new PrintStream(new FileOutputStream(fout));
		
		ps.println("# Reconos FPGA layout file (version 3.1.0a)");
		ps.println();
		ps.println("target");
		ps.println("\tdevice " + fpgaInfo.getName());
		ps.println("\tfamily " + fpgaInfo.getFamily());
		ps.println("end");
		
		for(Slot s : slots){
			ps.println();
			ps.println("slot " + s.getName());
			ps.println("\tslice_range " + s.getSliceRange().toString("SLICE_"));
			for(String name : fpgaInfo.getColumnRessourceNames()){
				Range r = s.getColumnRessourceRange(name);
				ps.println("\trange " + name + " " + r.toString(name + "_"));
			}
			for(BusMacro bm : s.getBusMacros()){
				s.fixBusMacroDirection(bm);
				ps.println("\tbusmacro");
				ps.println("\t\ttype " + bm);
				ps.println("\t\tloc X" + bm.getLocX() + "Y" + bm.getLocY());
				ps.println("\tend");
			}
			ps.println("end");
		}	
	}
	
	
	private String[] nextEntry(BufferedReader br) throws IOException{
		while(br.ready()){
			String line = br.readLine().trim();
			if(line.startsWith("#")) continue;
			if(line.length() == 0) continue;
			
			String [] keyvalue = line.split("=");
			if(keyvalue.length != 2) throw new IOException("Parse error: " + line);
			
			keyvalue[0] = keyvalue[0].trim();
			keyvalue[1] = keyvalue[1].trim();
			return keyvalue;
		}
		throw new IOException("parse error: unexpected end of file");
	}
	
	private void ioassert(boolean v) throws IOException {
		if(!v) throw new IOException("Parse error");
	}
	
	private ConfigParser createParser(){
		ConfigParser parser = new ConfigParser();
		
		parser.addNodeType(new ConfigNodeType("device"));
		parser.addNodeType(new ConfigNodeType("family"));
		parser.addNodeType(new ConfigNodeType("slice_range"));
		parser.addNodeType(new ConfigNodeType("range"));
		parser.addNodeType(new ConfigNodeType("type"));
		parser.addNodeType(new ConfigNodeType("loc"));
		parser.addNodeType(new ConfigNodeType("target",true));
		parser.addNodeType(new ConfigNodeType("slot",true));
		parser.addNodeType(new ConfigNodeType("busmacro",true));
		
		return parser;
	}
	
	public void read(File fin, DeviceDB db) throws IOException {
		ConfigNode root = createParser().read(fin);
		
		ConfigNode target = root.getChild("target");
		Vector<ConfigNode> slots = root.getChildren("slot");
		
		fpgaInfo = db.getDevice(target.getChild("device").getValue(0));
		
		this.slots = new Vector<Slot>();
		for(ConfigNode s : slots){
			String slotName = s.getValue(0);
			System.out.println(s.getChild("slice_range").getValue(0));
			Range sliceRange = new Range(s.getChild("slice_range").getValue(0) + ":" + s.getChild("slice_range").getValue(1));
			Slot slot = new Slot(slotName, sliceRange, fpgaInfo);
			this.slots.add(slot);
			
			Vector<ConfigNode> busmacros = s.getChildren("busmacro");
			ioassert(busmacros.size() == slot.getBusMacros().size());
			for(int j = 0; j < busmacros.size(); j++){
				String[] bmtype = busmacros.get(j).getChild("type").getValue(0).split("_");
				BusMacro bm = slot.getBusMacros().get(j);
				
				if(bm.getLogicalDirection() == BusMacro.INPUT){
					ioassert(bmtype.length == 3);
					
					ioassert(bmtype[0].equals("r2l") || bmtype[0].equals("l2r"));
					if(bmtype[0].equals("r2l")){
						bm.setPhysicalDirection(BusMacro.R2L);
					}
					if(bmtype[0].equals("l2r")){
						bm.setPhysicalDirection(BusMacro.L2R);
					}
					
					ioassert(bmtype[1].equals("sync") || bmtype[1].equals("async"));
					if(bmtype[1].equals("sync")){
						bm.setSync(true);
					}
					if(bmtype[1].equals("async")){
						bm.setSync(false);
					}
					
					ioassert(bmtype[2].equals("narrow") || bmtype[2].equals("wide"));
					if(bmtype[2].equals("narrow")){
						bm.setWidth(BusMacro.NARROW);
					}
					if(bmtype[2].equals("wide")){
						bm.setWidth(BusMacro.WIDE);
					}
				}
				if(bm.getLogicalDirection() == BusMacro.OUTPUT){
					ioassert(bmtype.length == 4);
					
					ioassert(bmtype[0].equals("r2l") || bmtype[0].equals("l2r"));
					if(bmtype[0].equals("r2l")){
						bm.setPhysicalDirection(BusMacro.R2L);
					}
					if(bmtype[0].equals("l2r")){
						bm.setPhysicalDirection(BusMacro.L2R);
					}
					
					ioassert(bmtype[1].equals("sync") || bmtype[1].equals("async"));
					if(bmtype[1].equals("sync")){
						bm.setSync(true);
					}
					if(bmtype[1].equals("async")){
						bm.setSync(false);
					}
					
					ioassert(bmtype[2].equals("enable"));
					
					ioassert(bmtype[3].equals("narrow") || bmtype[3].equals("wide"));
					if(bmtype[3].equals("narrow")){
						bm.setWidth(BusMacro.NARROW);
					}
					if(bmtype[3].equals("wide")){
						bm.setWidth(BusMacro.WIDE);
					}
				}
				
				String xy[] = busmacros.get(j).getChild("loc").getValue(0).split("Y");
				ioassert(xy.length == 2);
				int x = Integer.parseInt(xy[0].substring(1));
				int y = Integer.parseInt(xy[1]);
				bm.setLoc(x, y);
			}
		}
	}
	
	/*
	public void read(File fin, DeviceDB db) throws IOException {
		
		BufferedReader br = new BufferedReader(new FileReader(fin));
	
		String[] s;
		
		s = nextEntry(br);
		ioassert(s[0].equals("Device"));
		fpgaInfo = db.getDevice(s[1]);
		
		s = nextEntry(br);
		ioassert(s[0].equals("Family"));
		
		s = nextEntry(br);
		ioassert(s[0].equals("ReconosVersion"));
		
		s = nextEntry(br);
		ioassert(s[0].equals("Slots"));
		
		this.slots = new Vector<Slot>();
		int numSlots = Integer.parseInt(s[1]);
		
		for(int i = 0; i < numSlots; i++){
			s = nextEntry(br);
			ioassert(s[0].equals("SlotName"));
			String slotName = s[1];
			
			s = nextEntry(br);
			ioassert(s[0].equals("SliceRange"));
			Range sliceRange = new Range(s[1]);
			
			//s = nextEntry(br);
			//ioassert(s[0].equals("BRAMRange"));
			
			//s = nextEntry(br);
			//ioassert(s[0].equals("Mult18x18Range"));
			
			do{
				s = nextEntry(br);
			}
			while(s[0].startsWith("Range"));
			
			Slot slot = new Slot(slotName, sliceRange, fpgaInfo);
			slots.add(slot);
			
			ioassert(s[0].equals("BusMacros"));
			ioassert(Integer.parseInt(s[1]) == slot.getBusMacros().size());
			
			for(int j = 0; j < slot.getBusMacros().size(); j++){
				s = nextEntry(br);
				ioassert(s[0].equals("BusMacroType"));
				String[] bmtype = s[1].split("_");
				
				BusMacro bm = slot.getBusMacros().get(j);
				
				if(bm.getLogicalDirection() == BusMacro.INPUT){
					ioassert(bmtype.length == 3);
					
					ioassert(bmtype[0].equals("r2l") || bmtype[0].equals("l2r"));
					if(bmtype[0].equals("r2l")){
						bm.setPhysicalDirection(BusMacro.R2L);
					}
					if(bmtype[0].equals("l2r")){
						bm.setPhysicalDirection(BusMacro.L2R);
					}
					
					ioassert(bmtype[1].equals("sync") || bmtype[1].equals("async"));
					if(bmtype[1].equals("sync")){
						bm.setSync(true);
					}
					if(bmtype[1].equals("async")){
						bm.setSync(false);
					}
					
					ioassert(bmtype[2].equals("narrow") || bmtype[2].equals("wide"));
					if(bmtype[2].equals("narrow")){
						bm.setWidth(BusMacro.NARROW);
					}
					if(bmtype[2].equals("wide")){
						bm.setWidth(BusMacro.WIDE);
					}
				}
				if(bm.getLogicalDirection() == BusMacro.OUTPUT){
					ioassert(bmtype.length == 4);
					
					ioassert(bmtype[0].equals("r2l") || bmtype[0].equals("l2r"));
					if(bmtype[0].equals("r2l")){
						bm.setPhysicalDirection(BusMacro.R2L);
					}
					if(bmtype[0].equals("l2r")){
						bm.setPhysicalDirection(BusMacro.L2R);
					}
					
					ioassert(bmtype[1].equals("sync") || bmtype[1].equals("async"));
					if(bmtype[1].equals("sync")){
						bm.setSync(true);
					}
					if(bmtype[1].equals("async")){
						bm.setSync(false);
					}
					
					ioassert(bmtype[2].equals("enable"));
					
					ioassert(bmtype[3].equals("narrow") || bmtype[3].equals("wide"));
					if(bmtype[3].equals("narrow")){
						bm.setWidth(BusMacro.NARROW);
					}
					if(bmtype[3].equals("wide")){
						bm.setWidth(BusMacro.WIDE);
					}
				}
				
				s = nextEntry(br);
				ioassert(s[0].equals("BusMacroLocation"));
				ioassert(s.length == 2);
				
				String xy[] = s[1].split("Y");
				ioassert(xy.length == 2);
				int x = Integer.parseInt(xy[0].substring(1));
				int y = Integer.parseInt(xy[1]);
				
				bm.setLoc(x, y);
			}
		}
	}
	*/
}
