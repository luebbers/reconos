package de.upb.reconos.fpga;

import java.io.File;
import java.io.IOException;
import java.util.Set;
import java.util.TreeSet;
import java.util.Vector;


public class DeviceDB {
	private Vector<DeviceDescriptionFile> db; 
	
	public void readDir(String pathToDirectory) throws IOException{
		File dir = new File(pathToDirectory);
		
		String[] list = dir.list();
		if(list == null) return;
		
		db = new Vector<DeviceDescriptionFile>();
		
		for(int i = 0; i < list.length; i++){
			if(list[i].endsWith(".fpga")){
				read(new File(pathToDirectory + "/" + list[i]));
			}
		}
	}
	
	public void read(File fin) throws IOException{
		DeviceDescriptionFile fpga = new DeviceDescriptionFile();
		fpga.read(fin);
		db.add(fpga);
	}
	
	public Set<String> getFamilies() {
		Set<String> result = new TreeSet<String>();
		
		for(int i = 0; i < db.size(); i++){
			result.add(db.get(i).getFamily());
		}
		
		return result;
	}
	
	public Set<String> getDevices(String family) {
		Set<String> result = new TreeSet<String>();
		
		for(int i = 0; i < db.size(); i++){
			if(db.get(i).getFamily().equalsIgnoreCase(family)){
				result.add(db.get(i).getName());
			}
		}
		
		return result;
	}
	
	public DeviceInfo getDevice(String name) {
		for(int i = 0; i < db.size(); i++){
			if(db.get(i).getName().equalsIgnoreCase(name)){
				return db.get(i);
			}
		}
		return null;
	}	
	
}
