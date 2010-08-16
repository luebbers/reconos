package de.upb.reconos.layout.editor;

import java.util.Vector;

import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

public class Range {
	private Vector<ChangeListener> listeners;
	
	public Range(){
		listeners = new Vector<ChangeListener>();
	}
	
	public Range(String s){
		listeners = new Vector<ChangeListener>();
		parse(s);
	}
	
	public Range(Range r){
		listeners = new Vector<ChangeListener>();
		xMin = r.xMin;
		yMin = r.yMin;
		xMax = r.xMax;
		yMax = r.yMax;
	}
	
	public Range(int x_min, int y_min, int x_max, int y_max){
		listeners = new Vector<ChangeListener>();
		this.setXMin(x_min);
		this.setYMin(y_min);
		this.setXMax(x_max);
		this.setYMax(y_max);
	}
	
	private int xMin;
	private int yMin;
	private int xMax;
	private int yMax;
	
	public void parse(String s){
		String[] minMax = s.split(":");
		String[] minXY = minMax[0].split("Y");
		String[] maxXY = minMax[1].split("Y");
		
		yMin = Integer.parseInt(minXY[1]);
		yMax = Integer.parseInt(maxXY[1]);
		
		String[] tmp  = minXY[0].split("X");
		xMin = Integer.parseInt(tmp[tmp.length - 1]);
		
		tmp  = maxXY[0].split("X");
		xMax = Integer.parseInt(tmp[tmp.length - 1]);
	}
	
	public int getWidth(){ return getXMax() - getXMin() + 1; }
	public int getHeight(){ return getYMax() - getYMin() + 1; }
	
	public String toString(String rangeType){
		return rangeType + "X" + getXMin() + "Y" + getYMin() + ":"
				+ rangeType + "X" + getXMax() + "Y" + getYMax();
	}
	
	public String toString(){
		return toString("");
	}
	
	public int getArea(){
		return getWidth()*getHeight();
	}
	
	public void addChangeListener(ChangeListener l){
		listeners.add(l);
	}
	public void setXMin(int xMin) {
		this.xMin = xMin;
		updateListeners();
	}
	public int getXMin() {
		return xMin;
	}
	public void setYMin(int yMin) {
		this.yMin = yMin;
		updateListeners();
	}
	public int getYMin() {
		return yMin;
	}
	public void setXMax(int xMax) {
		this.xMax = xMax;
		updateListeners();
	}
	public int getXMax() {
		return xMax;
	}
	public void setYMax(int yMax) {
		this.yMax = yMax;
		updateListeners();
	}
	public int getYMax() {
		return yMax;
	}
	
	private void updateListeners(){
		for(ChangeListener l : listeners) l.stateChanged(new ChangeEvent(this));
	}
	
	public boolean contains(Range r){
		if(r.xMax > xMax || r.yMax > yMax) return false;
		if(r.xMin < xMin || r.yMin < yMin) return false;
		return true;
	}
	
	public boolean intersects(Range r){
		if(r.getXMax() >= getXMin() && r.getXMin() <= getXMax()
		&& r.getYMax() >= getYMin() && r.getYMin() <= getYMax()) return true;
		return false;
	}
}
