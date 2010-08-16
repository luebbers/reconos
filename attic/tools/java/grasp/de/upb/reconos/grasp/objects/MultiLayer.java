package de.upb.reconos.grasp.objects;

import java.io.Serializable;
import java.util.Vector;

public class MultiLayer<T> implements Serializable {

	private static final long serialVersionUID = 1L;
	private Vector<T> elements;
	private int[] layerIndices;
	
	public MultiLayer(int layers){
		elements = new Vector<T>();
		layerIndices = new int[layers];
	}
	
	public Vector<T> getElements(){
		return elements;
	}
	
	public void insert(T d, int layer){
		elements.add(layerIndices[layer], d);
		for(int i = layer + 1; i < layerIndices.length; i++){
			layerIndices[i]++;
		}
	}
	
	public void remove(T d){
		while(removeOnce(d));
	}
	
	private boolean removeOnce(T d){
		int idx = elements.indexOf(d);
		if(idx == -1) return false;
		elements.remove(idx);
		for(int i = 0; i < layerIndices.length; i++){
			if(layerIndices[i] > idx) layerIndices[i]--;
		}
		return true;
	}
	
}
