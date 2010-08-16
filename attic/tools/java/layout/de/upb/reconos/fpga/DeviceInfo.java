 package de.upb.reconos.fpga;

import java.util.HashSet;
import java.util.Set;
import java.util.Vector;

import de.upb.reconos.layout.BusMacro;
import de.upb.reconos.layout.editor.Range;

public abstract class DeviceInfo
{
	
	private Vector<ColumnRessource> columnRessources;
	private Vector<BlockRessource> blockRessources;
	
	public DeviceInfo(){
		columnRessources = new Vector<ColumnRessource>();
		blockRessources = new Vector<BlockRessource>();
	}
	
	public void addColumnRessource(ColumnRessource r){
		columnRessources.add(r);
	}
	
	public void addBlockRessource(BlockRessource b){
		blockRessources.add(b);
	}
	
	public Vector<BlockRessource> getBlockRessources(String name){
		if(name == null){
			return blockRessources;
		}
		else {
			Vector<BlockRessource> result = new Vector<BlockRessource>();
			for(BlockRessource br : blockRessources){
				if(br.getName().equalsIgnoreCase("name")) result.add(br);
			}
			return result;
		}
	}
	
	public Vector<ColumnRessource> getColumnRessources(String name){
		if(name == null){
			return columnRessources;
		}
		else {
			Vector<ColumnRessource> result = new Vector<ColumnRessource>();
			for(ColumnRessource br : columnRessources){
				if(br.getName().equalsIgnoreCase("name")) result.add(br);
			}
			return result;
		}
	}
	
	public boolean isValidAGSliceRange(Range range){
		//System.out.print("check odd/even : ");
		if(range.getXMin() % 2 == 1 || range.getYMin() % 2 == 1
				|| range.getXMax() % 2 == 0 || range.getYMax() % 2 == 0) return false;

		//System.out.println("passed");
		//System.out.print("check boxes :");
		
		for(BlockRessource b : blockRessources){
			if(range.intersects(b.range)) return false;
		}
		
		//System.out.println("passed");
		//System.out.print("check min/max : ");
		
		if(range.getXMin() < 0 || range.getYMin() < 0) return false;
		if(range.getXMax() >= getWidth() || range.getYMax() >= getHeight()) return false;
		
		//System.out.println("passed");
		//System.out.print("check brams : ");
		
		for(ColumnRessource b : columnRessources){
			if(range.getXMax() == b.slice_x - 1 || range.getXMin() == b.slice_x) return false;
			if(b.slice_x >= range.getXMin() && b.slice_x <= range.getXMax()){
				if(b.slice_y_min < range.getYMax() && b.slice_y_max - 1 > range.getYMax()
				|| b.slice_y_min < range.getYMin() && b.slice_y_max - 1 > range.getYMin()){
					return false;
				}
			}
		}
		
		//System.out.println("all checks : PASSED");
		
		return true;	
	}
	
	public boolean isValidBusMacro(BusMacro bm){
		if(bm.getLocX() % 2 != 0) return false;
		if(bm.getLocY() % 2 != 0) return false;
		
		Range range = bm.getRange();
		Range rangeA = bm.getRangeA();
		Range rangeB = bm.getRangeB();
		
		for(BlockRessource b : blockRessources){
			if(b.busmacro_permit) continue;
			if(rangeA.intersects(b.range)) return false;
			if(rangeB.intersects(b.range)) return false;
		}
		for(ColumnRessource b : columnRessources){
			if(b.busmacro_permit) continue;
			if(b.slice_x > range.getXMin() && b.slice_x <= range.getXMax()
			&& b.slice_y_min < range.getYMax() && b.slice_y_max > range.getYMin()) return false;
		}
		
		if(range.getXMin() < 0 || range.getXMax() >= getWidth()) return false;
		if(range.getYMin() < 0 || range.getYMax() >= getHeight()) return false;
		return true;
	}
	
	public Vector<ColumnRessource> getColumnRessource(String name, Range sliceRange){
		Vector<ColumnRessource> result = new Vector<ColumnRessource>();
		
		for(ColumnRessource v : columnRessources){
			if(!v.getName().equals(name)) continue;
			if(v.slice_y_min >= sliceRange.getYMin() && v.slice_y_max <= sliceRange.getYMax() + 1 
					&& v.slice_x > sliceRange.getXMin() && v.slice_x <= sliceRange.getXMax()) result.add(v);
		}
		
		return result;
	}
	
	public Set<String> getColumnRessourceNames(){
		Set<String> result = new HashSet<String>();
		
		for(ColumnRessource r : columnRessources){
			result.add(r.getName());
		}
		
		return result;
	}
	
	public Set<String> getBlockRessourceNames(){
		Set<String> result = new HashSet<String>();
		
		for(BlockRessource r : blockRessources){
			result.add(r.getName());
		}
		
		return result;
	}
	
	public abstract String getName();
	public abstract String getFamily();
	public abstract int getWidth();
	public abstract int getHeight();
}
