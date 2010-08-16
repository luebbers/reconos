package de.upb.reconos.parser;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Stack;
import java.util.Vector;

public class ConfigParser {
	private Map<String, ConfigNodeType> nodeTypes;
	
	public ConfigParser(){
		nodeTypes = new HashMap<String, ConfigNodeType>();
	}
	
	public void addNodeType(ConfigNodeType nodeType){
		nodeTypes.put(nodeType.getKeyword(), nodeType);
	}
	
	private Vector<String> nextLine(BufferedReader br) throws IOException {
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
	
	public ConfigNode read(File fin) throws IOException {
		BufferedReader br = new BufferedReader(new FileReader(fin));
		Stack<ConfigNode> stack = new Stack<ConfigNode>();
		ConfigNode rootNode = new ConfigNode(new ConfigNodeType(null,true),null);
		stack.push(rootNode);
		
		while(true){
			Vector<String> entry = nextLine(br);
			if(entry == null) break;
			
			if(entry.get(0).equals("end")){
				if(stack.pop() == rootNode) throw new IOException("parse error");
				continue;
			}
			
			ConfigNodeType type = nodeTypes.get(entry.get(0));
			if(type == null){
				System.out.println("type null for " + entry.get(0));
			}
			Vector<String> values = new Vector<String>();
			for(int i = 1; i < entry.size(); i++) values.add(entry.get(i));
			
			ConfigNode cn = new ConfigNode(type,values);
			stack.peek().addChild(cn);
			
			if(cn.getType().isContainer()) stack.push(cn);
		}
		if(stack.pop() != rootNode) throw new IOException("parse error");
		
		return rootNode;
	}
}
