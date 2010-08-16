package de.upb.reconos.layout.editor;

import java.awt.event.ActionEvent;

import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;

import de.upb.reconos.layout.Layout;
import de.upb.reconos.layout.Slot;




public class PRRMenu extends ContextMenu {

	private static final long serialVersionUID = 1L;
	
	private Layout layout;
	private Slot slot;
	private ChangeListener listener;
	
	public PRRMenu(Layout l, ChangeListener li, Slot s){
		layout = l;
		listener = li;
		slot = s;
		addItem("Remove Slot");
	}
	
	public void actionPerformed(ActionEvent e){
		if(e.getActionCommand().toLowerCase().startsWith("remove slot")){
			System.out.println("remove slot");
			layout.removeSlot(slot);
			listener.stateChanged(new ChangeEvent(this));
		}
	}
}
