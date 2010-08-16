package de.upb.reconos.grasp.io;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class Configuration {
	
	private Map<String, String> configMap;
	
	public Configuration(){
		configMap = new HashMap<String, String>();
	}
	
	public void read(String filename) throws IOException {
		BufferedReader br = new BufferedReader(new FileReader(filename));
		
		while(br.ready()){
			String line = br.readLine().trim();
			if(line.startsWith("#")) continue;
			
			String[] s = line.split(" ",2);
			configMap.put(s[0].trim(), s[1].trim());
		}
	}
	
	public boolean containsKey(String key){
		return configMap.containsKey(key);
	}
	
	public String getString(String key, String defaultValue){
		if(containsKey(key)) return configMap.get(key);
		return defaultValue;
	}
	
	public int getInt(String key, int defaultValue){
		try{
			return Integer.parseInt(configMap.get(key));
		}
		catch (NullPointerException npe) {}
		catch (NumberFormatException nfe){}
		
		return defaultValue;
	}
	
	public double getDouble(String key, double defaultValue){
		try{
			return Double.parseDouble(configMap.get(key));
		}
		catch (NullPointerException npe) {}
		catch (NumberFormatException nfe){}
		
		return defaultValue;
	}
}
