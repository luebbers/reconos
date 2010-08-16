package de.upb.reconos.parser;

import java.util.Vector;

public class ConfigNode {
	private ConfigNodeType type;
	private Vector<String> values;
	private Vector<ConfigNode> children;
	
	public ConfigNode(ConfigNodeType type, Vector<String> values){
		this.type = type;
		this.values = values;
		children = new Vector<ConfigNode>();
	}
	
	public ConfigNode combineChildren(String keyword){
		Vector<ConfigNode> nodes = getChildren(keyword);
		Vector<String> values = new Vector<String>();
		for(ConfigNode n : nodes) values.addAll(n.getValues());
		
		ConfigNode comb = new ConfigNode(nodes.get(0).getType(),values);
		return comb;
	}
	
	public ConfigNodeType getType() {
		return type;
	}
	
	public String getValue(int idx){
		return values.get(idx);
	}
	
	public int getIntValue(int idx){
		return Integer.parseInt(getValue(idx));
	}
	
	public boolean getBooleanValue(int idx){
		return Boolean.parseBoolean(getValue(idx));
	}
	
	public Vector<String> getValues(){
		return values;
	}
	
	public int[] getIntArrayValue(){
		int[] result = new int[getValueCount()];
		for(int i = 0; i < getValueCount(); i++){
			result[i] = getIntValue(i);
		}
		return result;
	}
	
	public int getValueCount(){
		return values.size();
	}
	
	public int getChildCount(){
		return children.size();
	}
	
	public ConfigNode getChild(int idx){
		return children.get(idx);
	}
	
	public ConfigNode getChild(String keyword){
		Vector<ConfigNode> tmp = getChildren(keyword);
		if(tmp == null) return null;
		if(tmp.size() == 0) return null;
		return tmp.get(0);
	}
	
	public void addChild(ConfigNode cn){
		children.add(cn);
	}
	
	public Vector<ConfigNode> getChildren(String keyword){
		if(keyword == null) return children;
		Vector<ConfigNode> result = new Vector<ConfigNode>();
		for(ConfigNode c : children){
			if(c.type.getKeyword().equals(keyword)) result.add(c);
		}
		if(result.size() == 0) return null;
		return result;
	}
	
	public Vector<ConfigNode> getChildren(){
		return getChildren(null);
	}
}
