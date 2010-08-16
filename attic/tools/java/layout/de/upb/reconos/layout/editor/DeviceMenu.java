package de.upb.reconos.layout.editor;

import java.awt.event.ActionEvent;

import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

import de.upb.reconos.layout.Layout;






public class DeviceMenu extends ContextMenu {

	private static int slotCounter = 0;
	private static final long serialVersionUID = 1L;
	protected Layout layout;
	protected ChangeListener listener;
	
	public DeviceMenu(Layout l, ChangeListener li){
		this.layout = l;
		addItem("Add Slot");
		listener = li;
	}
	
	public void actionPerformed(ActionEvent e){
		if(e.getActionCommand().toLowerCase().equals("add slot")){
			if(layout == null) System.err.println("layout == null");
			if(pos == null) System.err.println("pos == null");
			layout.createSlot((int)pos.getX(),(int)pos.getY(), "hw_task_" + slotCounter++);
			if(listener != null) listener.stateChanged(new ChangeEvent(this));
		}
	}
}