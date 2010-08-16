package de.upb.reconos.layout;

import java.util.Vector;

import de.upb.reconos.fpga.ColumnRessource;
import de.upb.reconos.fpga.DeviceInfo;
import de.upb.reconos.layout.editor.Range;

public class Slot {
	private DeviceInfo fpga;
	private Range sliceRange;
	private String name;
	private Vector<BusMacro> busMacros;
	
	public Slot(int x, int y, String name, DeviceInfo fpga){
		this.sliceRange = new Range(x,y,x + 15, y + 59);
		this.name = name;
		this.fpga = fpga;
		createBusMacros();
	}

	public Slot(String name, Range sliceRange, DeviceInfo fpga){
		this.sliceRange = sliceRange;
		this.name = name;
		this.fpga = fpga;
		createBusMacros();
	}
	
	public String getName() {
		return name;
	}

	public Range getSliceRange() {
		return sliceRange;
	}
	
	public Range getColumnRessourceRange(String name) {
		Range r = new Range(fpga.getWidth() + 1, fpga.getHeight() + 1, -1, -1);
		Vector<ColumnRessource> res = fpga.getColumnRessource(name,sliceRange);
		for(ColumnRessource b : res){
			if(b.getX() < r.getXMin()) r.setXMin(b.getX());
			if(b.getX() > r.getXMax()) r.setXMax(b.getX());
			if(b.getY() < r.getYMin()) r.setYMin(b.getY());
			if(b.getY() > r.getYMax()) r.setYMax(b.getY());
		}
		return r;		
	}
	
	public void createBusMacros(){
		busMacros = new Vector<BusMacro>();
		for(int i = 0; i < 14; i++){
			BusMacro bm = new BusMacro(BusMacro.OUTPUT, BusMacro.L2R);
			bm.setLoc(sliceRange.getXMax() - 1, sliceRange.getYMin() + i*2);
			bm.setSlot(this);
			bm.setEnable(true);
			busMacros.add(bm);
		}
		for(int i = 0; i < 16; i++){
			BusMacro bm = new BusMacro(BusMacro.INPUT, BusMacro.R2L);
			bm.setLoc(sliceRange.getXMax() - 1, sliceRange.getYMin() + i*2 + 28);
			bm.setSlot(this);
			bm.setEnable(false);
			busMacros.add(bm);
		}
	}
	
	public boolean isValidBusMacro(int idx){
		BusMacro bm = busMacros.get(idx);
		boolean a = getSliceRange().contains(bm.getRangeA());
		boolean b = getSliceRange().contains(bm.getRangeB());
	
		if(!(a ^ b)) return false;
		return true;
	}
	
	public void fixBusMacroDirection(BusMacro bm){
		boolean a = getSliceRange().contains(bm.getRangeA());
		boolean b = getSliceRange().contains(bm.getRangeB());
		
		if(!(a ^ b)) return;
		
		if(bm.getLogicalDirection() == BusMacro.INPUT){
			if(a) bm.setPhysicalDirection(BusMacro.R2L);
			else bm.setPhysicalDirection(BusMacro.L2R);
		}
		if(bm.getLogicalDirection() == BusMacro.OUTPUT){
			if(a) bm.setPhysicalDirection(BusMacro.L2R);
			else bm.setPhysicalDirection(BusMacro.R2L);
		}		
		
	}

	public Vector<BusMacro> getBusMacros() {
		return busMacros;
	}
}
