package de.upb.reconos.fpga;

import java.awt.Color;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.util.HashSet;
import java.util.Set;
import java.util.Vector;

import de.upb.reconos.layout.editor.Range;
import de.upb.reconos.parser.ConfigNode;
import de.upb.reconos.parser.ConfigNodeType;
import de.upb.reconos.parser.ConfigParser;

public class DeviceDescriptionFile extends DeviceInfo {

	private String name;
	private String family;
	private int width;
	private int height;
	
	public String getName() {
		return name;
	}
	
	public String getFamily(){
		return family;
	}
	
	private void addColumnRessources(String ressourceName,
			int size, int[] columns, int[] rows, Set<int[]> exclude,
			boolean bm_permit, boolean display, Color color)
	{
		int[] pos = new int[2];
		for(pos[0] = 0; pos[0] < columns.length; pos[0]++){
			int slice_x = columns[pos[0]];
			for(pos[1] = 0; pos[1] < rows.length; pos[1]++){
				//if(exclude.contains(pos)) continue;
				boolean cont = false;
				for(int[] ex : exclude){
					if(ex[0] == pos[0] && ex[1] == pos[1]) cont = true;
				}
				if(cont) continue;
				
				int slice_y = rows[pos[1]];
				
				ColumnRessource cr = new ColumnRessource(ressourceName,slice_y,slice_y + size,slice_x,pos[0],pos[1]);
				cr.busmacro_permit = bm_permit;
				cr.display = display;
				if(color != null) cr.color = color;
				//System.out.println("adding column ressource " + ressourceName + ", pos = " + slice_x + "," + slice_y);
				addColumnRessource(cr);
			}
		}
	}
	
	private void addBlockRessources(String ressourceName,
			int[] size, Set<int[]> pos, boolean busmacro_permit, boolean display, Color color)
	{
		for(int[] p : pos){
			Range r = new Range(p[0],p[1],p[0] + size[0] - 1, p[1] + size[1] - 1);
			//System.out.println("adding block ressource " + ressourceName + ", range = " + r);
			BlockRessource br = new BlockRessource(ressourceName,r);
			br.busmacro_permit = busmacro_permit;
			br.display = display;
			if(color != null) br.color = color;
			addBlockRessource(br);
		}
	}
	
	public Vector<String> nextEntry(BufferedReader br) throws IOException {
		while(br.ready()){
			String line = br.readLine().trim();
			if(line.startsWith("#")) continue;
			if(line.length() == 0) continue;
			
			Vector<String> res = new Vector<String>();
			
			String s[] = line.split("\\W");
			for(int i = 0; i < s.length; i++){
				s[i] = s[i].trim();
				if(s[i].length() > 0) res.add(s[i]);
			}
			
			if(res.size() > 0) return res;
		}
		return null;
	}
	
	private ConfigParser createParser(){
		ConfigParser parser = new ConfigParser();
		parser.addNodeType(new ConfigNodeType("device_name"));
		parser.addNodeType(new ConfigNodeType("device_family"));
		parser.addNodeType(new ConfigNodeType("size"));
		parser.addNodeType(new ConfigNodeType("columns"));
		parser.addNodeType(new ConfigNodeType("rows"));
		parser.addNodeType(new ConfigNodeType("exclude"));
		parser.addNodeType(new ConfigNodeType("display_color"));
		parser.addNodeType(new ConfigNodeType("busmacro_permit"));
		parser.addNodeType(new ConfigNodeType("block"));
		parser.addNodeType(new ConfigNodeType("column_ressource",true));
		parser.addNodeType(new ConfigNodeType("block_ressource",true));
		return parser;
	}
	
	private void parseColumnRessources(ConfigNode crn){
		boolean display = true;
		
		int size = crn.getChild("size").getIntValue(0);
		boolean bm_permit = false;
		if(crn.getChild("busmacro_permit") != null){
			System.out.println(crn.getChild("busmacro_permit"));
			crn.getChild("busmacro_permit").getBooleanValue(0);
		}
		int[] rows = crn.combineChildren("rows").getIntArrayValue();
		int[] cols = crn.combineChildren("columns").getIntArrayValue();
		int[] excl = null;
		if(crn.getChildren("exclude") != null) excl = crn.combineChildren("exclude").getIntArrayValue();
		int[] tmp = crn.getChild("display_color").getIntArrayValue();
		Color displayColor = new Color(tmp[0],tmp[1],tmp[2]);
		Set<int[]> exclude = new HashSet<int[]>();
		if(excl != null){
			for(int i = 0; i < excl.length; i += 2){
				int[] ex = new int[2];
				ex[0] = excl[i];
				ex[1] = excl[i + 1];
				exclude.add(ex);
			}
		}
		for(String rn : crn.getValues()){
			addColumnRessources(rn,size,cols,rows,exclude,bm_permit,display,displayColor);
			display = false;
		}			
	}
	
	private void parseBlockRessources(ConfigNode brn){
		int[] size = brn.getChild("size").getIntArrayValue();
		boolean bm_permit = false;	
		if(brn.getChild("busmacro_permit") != null) brn.getChild("busmacro_permit").getBooleanValue(0);
		int[] tmp = brn.getChild("display_color").getIntArrayValue();
		Color displayColor = new Color(tmp[0],tmp[1],tmp[2]);
		int[] pos = brn.combineChildren("block").getIntArrayValue();
		Set<int[]> blocks = new HashSet<int[]>();
		for(int i = 0; i < pos.length; i += 2){
			int[] p = new int[2];
			p[0] = pos[i];
			p[1] = pos[i + 1];
			blocks.add(p);
		}		
	
		for(String rn : brn.getValues()){
			addBlockRessources(rn,size,blocks,bm_permit,true,displayColor);
		}		
	}
	
	public void read(File fin) throws IOException {
		ConfigNode cfg = createParser().read(fin);
		
		width = cfg.getChild("size").getIntValue(0);
		height = cfg.getChild("size").getIntValue(1);
		name = cfg.getChild("device_name").getValue(0);
		family = cfg.getChild("device_family").getValue(0);
		
		Vector<ConfigNode> columnRessourceNodes = cfg.getChildren("column_ressource");
		for(ConfigNode crn : columnRessourceNodes){
			System.out.println(crn);
			parseColumnRessources(crn);
		}
		
		Vector<ConfigNode> blockRessourceNodes = cfg.getChildren("block_ressource");
		for(ConfigNode brn : blockRessourceNodes){
			parseBlockRessources(brn);
		}
	}
	
	/*
	public void read(File fin) throws IOException {
		BufferedReader br = new BufferedReader(new FileReader(fin));

		Vector<Integer> columns = null;
		Vector<Integer> rows = null;
		int size[] = null;
		boolean busmacro_permit = false;
		Color display_color = null;
		
		Set<String> ressourceNames = null;
		Set<int[]> exclude = null;
		Set<int[]> blocks = null;
		
		final int STATE_TOPLEVEL = 0;
		final int STATE_COLUMN_RESSOURCE = 1;
		final int STATE_BLOCK_RESSOURCE = 2;
		
		int state = STATE_TOPLEVEL;
		
		while(true){
			Vector<String> entry = nextEntry(br);
			if(entry == null) break;
			switch(state){
				case STATE_TOPLEVEL:
					if(entry.get(0).equals("size")){
						width = Integer.parseInt(entry.get(1));
						height = Integer.parseInt(entry.get(2));
					}
					else if(entry.get(0).equals("device_name")){
						name = entry.get(1);
					}
					else if(entry.get(0).equals("device_family")){
						family = entry.get(1);
					}
					
					else if(entry.get(0).equals("column_ressource")){
						ressourceNames = new HashSet<String>();
						for(int i = 1; i < entry.size(); i++) ressourceNames.add(entry.get(i));
						size = null;
						busmacro_permit = false;
						columns = new Vector<Integer>();
						rows = new Vector<Integer>();
						exclude = new HashSet<int[]>();
						blocks = new HashSet<int[]>();
						display_color = null;
						state = STATE_COLUMN_RESSOURCE;
					}
					else if(entry.get(0).equals("block_ressource")){
						ressourceNames = new HashSet<String>();
						for(int i = 1; i < entry.size(); i++) ressourceNames.add(entry.get(i));
						display_color = null;
						busmacro_permit = false;
						state = STATE_BLOCK_RESSOURCE;
					}
					break;
				case STATE_COLUMN_RESSOURCE:
					if(entry.get(0).equals("size")){
						size = new int[1];
						size[0] = Integer.parseInt(entry.get(1));
					}
					else if(entry.get(0).equals("busmacro_permit")){
						busmacro_permit = Boolean.parseBoolean(entry.get(1));
					}
					else if(entry.get(0).equals("display_color")){
						int r = Integer.parseInt(entry.get(1));
						int g = Integer.parseInt(entry.get(2));
						int b = Integer.parseInt(entry.get(3));
						display_color = new Color(r,g,b);
					}
					else if(entry.get(0).equals("columns")){
						for(int i = 1; i < entry.size(); i++){
							columns.add(Integer.parseInt(entry.get(i)));
						}
					}
					else if(entry.get(0).equals("rows")){
						for(int i = 1; i < entry.size(); i++){
							rows.add(Integer.parseInt(entry.get(i)));
						}
					}
					else if(entry.get(0).equals("exclude")){
						for(int i = 1; i < entry.size(); i += 2){
							int pos[] = new int[2];
							pos[0] = Integer.parseInt(entry.get(i));
							pos[1] = Integer.parseInt(entry.get(i + 1));
							exclude.add(pos);
						}
					}
					else if(entry.get(0).equals("end")){
						boolean display = true;
						int[] r = new int[rows.size()];
						int[] c = new int[columns.size()];
						for(int i = 0; i < r.length; i++) r[i] = rows.get(i);
						for(int i = 0; i < c.length; i++) c[i] = columns.get(i);
						for(String rn : ressourceNames){
							addColumnRessources(rn,size[0],c,r,exclude,busmacro_permit,display,display_color);
							display = false;
						}
						state = STATE_TOPLEVEL;
					}
					break;
				case STATE_BLOCK_RESSOURCE:
					if(entry.get(0).equals("size")){
						size = new int[2];
						size[0] = Integer.parseInt(entry.get(1));
						size[1] = Integer.parseInt(entry.get(2));
					}
					else if(entry.get(0).equals("busmacro_permit")){
						busmacro_permit = Boolean.parseBoolean(entry.get(1));
					}
					else if(entry.get(0).equals("display_color")){
						int r = Integer.parseInt(entry.get(1));
						int g = Integer.parseInt(entry.get(2));
						int b = Integer.parseInt(entry.get(3));
						display_color = new Color(r,g,b);
					}
					else if(entry.get(0).equals("block")){
						int pos[] = new int[2];
						pos[0] = Integer.parseInt(entry.get(1));
						pos[1] = Integer.parseInt(entry.get(2));
						blocks.add(pos);
					}
					else if(entry.get(0).equals("end")){
						for(String rn : ressourceNames){
							addBlockRessources(rn,size,blocks,busmacro_permit,true,display_color);
						}
						state = STATE_TOPLEVEL;
					}
					break;
			}
		}
	}
	*/
	public int getHeight() {
		return height;
	}

	public int getWidth() {
		return width;
	}

}
