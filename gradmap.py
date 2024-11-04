# -*- coding: utf-8 -*-
"""
@author: adam.novak@skgeodesy.sk
"""

import tkinter as tk
from tkinter import filedialog
from tkinter import font

class App(tk.Frame):
    def __init__(self, master=None):
        super().__init__(master)
        self.pack()
        self.create_widgets()

    def create_widgets(self):
        # Main window
        self.master.title("GradMap v1.0")
        self.master.geometry('500x650')  # Adjusted size to accommodate widgets
        self.master.resizable(True, True)
        
        custom_font = font.Font(family="Trebuchet MS", size=int(11.5))  # font for standard widget labels
        custom_font_panel = font.Font(family="Trebuchet MS", size= int(11.5), weight="bold")  # font for labeling panel names
        custom_font_display = font.Font(family="Trebuchet MS", size= int(9))  # font for displaying filnames
        custom_font_widgets = font.Font(family="Trebuchet MS", size= int(10))  # font displayed within entry window widgets

        p1 = tk.LabelFrame(self.master, text='Input Data', bg='#f0f0f0', relief=tk.GROOVE, borderwidth=2.5,font=custom_font_panel)
        p1.place(relx=0.02, rely=0.01, relwidth=0.96, relheight=0.23)
        panel1textheight = 0.25
        
        button_choose_file = tk.Button(p1, text="Choose file(s)", bg='#e7e7e7', command=self.choose_input_files, font=custom_font)
        button_choose_file.place(relx=0.02, rely=0.05, relwidth=0.3, relheight=0.3)
        self.show_local_path = tk.Label(p1, text="", bg='#f0f0f0', anchor="w", font=custom_font_display)
        self.show_local_path.place(relx=0.35, rely=0.05, relwidth=0.6, relheight= panel1textheight)

        label_instrument = tk.Label(p1, text="instrument type", bg='#f0f0f0', anchor="w", font=custom_font)
        label_instrument.place(relx=0.02, rely=0.44, relwidth=0.35, relheight= panel1textheight)
        
        self.instrument_var = tk.StringVar(value="Scintrex CG5")
        instrument_options = tk.OptionMenu(p1, self.instrument_var, "Scintrex CG5", "CG6 Autograv")
        instrument_options.place(relx=0.7, rely=0.43, relwidth=0.26, relheight=panel1textheight)

        label_header_lines = tk.Label(p1, text="number of header lines", bg='#f0f0f0', anchor="w", font=custom_font)
        label_header_lines.place(relx=0.02, rely=0.72, relwidth=0.34, relheight=panel1textheight)
        
        self.entry_header_lines = tk.Entry(p1, font=custom_font_widgets, justify='center')
        self.entry_header_lines.insert(0, 34)
        self.entry_header_lines.place(relx=0.74, rely=0.72, relwidth=0.1, relheight=panel1textheight-0.04)
   
    
        # Panel 2 - Processing
        p2 = tk.LabelFrame(self.master, text='Processing', bg='#f0f0f0', relief=tk.GROOVE, borderwidth=2,font = custom_font_panel)
        p2.place(relx=0.02, rely=0.24, relwidth=0.96, relheight=0.32)
        
        panel2textheight = 0.18
        
        # Settings Panel in Processing
        label_measured_positions = tk.Label(p2, text='number of measured positions', bg='#f0f0f0', anchor="w", font=custom_font)
        label_measured_positions.place(relx=0.02, rely=0.1, relwidth=0.5, relheight= panel2textheight)

        label_rejection_threshold = tk.Label(p2, text='rejection threshold in µGal', bg='#f0f0f0', anchor="w", font=custom_font)
        label_rejection_threshold.place(relx=0.02, rely=0.28, relwidth=0.5, relheight= panel2textheight)

        label_gradient_format = tk.Label(p2, text='gradient format', bg='#f0f0f0', anchor="w", font=custom_font)
        label_gradient_format.place(relx=0.02, rely=0.46, relwidth=0.5, relheight= panel2textheight)
        
        label_significance_level = tk.Label(p2, text='significance level', bg='#f0f0f0', anchor="w", font=custom_font)
        label_significance_level.place(relx=0.02, rely=0.63, relwidth=0.5, relheight= panel2textheight)
        
        label_calibration_factor = tk.Label(p2, text='calibration factor', bg='#f0f0f0', anchor="w", font=custom_font)
        label_calibration_factor.place(relx=0.02, rely=0.8, relwidth=0.5, relheight = panel2textheight)

        self.measured_positions_options = tk.OptionMenu(p2, tk.StringVar(value="2"), "2", "3", "from file")
        self.measured_positions_options.place(relx=0.72, rely=0.1, relwidth=0.12, relheight=0.15)
        
        self.entry_rejection_threshold = tk.Entry(p2, font=custom_font_widgets, justify='center')
        self.entry_rejection_threshold.insert(0,5)  # Prefill with the default value 5
        self.entry_rejection_threshold.place(relx=0.74, rely=0.29, relwidth=0.1, relheight= panel2textheight)

        gradient_format_options = tk.OptionMenu(p2, tk.StringVar(value="linear"), "linear", "function")
        gradient_format_options.place(relx=0.72, rely=0.45, relwidth=0.16, relheight=0.15)

        significance_level_options = tk.OptionMenu(p2, tk.StringVar(value = "2-σ .."), "1-σ (68% confidence bounds)", "2-σ (95% confidence bounds)", "3-σ (99.7% confidence bounds)")
        significance_level_options.place(relx=0.72, rely=0.62, relwidth=0.18, relheight=0.15)

        entry_calibration_factor = tk.Entry(p2, font=custom_font_widgets, justify='center')
        entry_calibration_factor.place(relx=0.74, rely=0.81, relwidth=0.1, relheight= panel2textheight)



        # Panel 3
        p3 = tk.LabelFrame(self.master, text='Output data', bg='#f0f0f0', relief=tk.GROOVE, borderwidth=2, font=custom_font_panel)
        p3.place(relx=0.02, rely=0.64, relwidth=0.96, relheight=0.27)

        # Panel na vyber suboru
        button_create_report = tk.Button(p3, text="Create report file", bg='#e7e7e7', command=self.create_report_file, font=custom_font)
        button_create_report.place(relx=0.02, rely=0.05, relwidth=0.35, relheight=0.22)

        # Vypis nazvu vybraneho suboru
        self.show_report_path = tk.Label(p3, text="", bg='#f0f0f0', anchor="w", font=custom_font)
        self.show_report_path.place(relx= 0.45, rely=0.05, relwidth=0.45, relheight=0.15)

        # save graphic output label
        label_store_processing_figures = tk.Label(p3, text="store processing figures", bg='#f0f0f0', anchor="w", font=custom_font)
        label_store_processing_figures.place(relx= 0.02, rely=0.35, relwidth=0.4, relheight=0.15)

        # text for saving summary of all calculations in an excel table
        label_save_summary = tk.Label(p3, text="save summary in table", bg='#f0f0f0', anchor="w", font=custom_font)
        label_save_summary.place(relx= 0.02, rely=0.55, relwidth=0.38, relheight=0.15)

        # text for saving gravity differences instead of gradient for all calculations
        label_save_gravity_diff = tk.Label(p3, text="save gravity differences instead", bg='#f0f0f0', anchor="w", font=custom_font)
        label_save_gravity_diff.place(relx= 0.02, rely=0.75, relwidth=0.53, relheight=0.15)

        # button for saving graphic output
        self.check_graphics_var = tk.BooleanVar(value=False)
        check_graphics = tk.Checkbutton(p3, text='', variable=self.check_graphics_var, bg='#f0f0f0')
        check_graphics.place(relx= 0.77, rely=0.35, relwidth=0.09, relheight=0.15)

        # Button for saving a summary (table) of all calculated values
        self.check_summary_var = tk.BooleanVar(value=True)
        check_summary = tk.Checkbutton(p3, text='', variable=self.check_summary_var, bg='#f0f0f0')
        check_summary.place(relx=0.77, rely=0.55, relwidth=0.09, relheight=0.15)

        # button for saving gravity differences instead of gradient for all calculations
        self.check_gravity_dif_var = tk.BooleanVar(value=False)
        check_gravity_dif = tk.Checkbutton(p3, text='', variable=self.check_gravity_dif_var, bg='#f0f0f0')
        check_gravity_dif.place(relx= 0.77, rely=0.75, relwidth=0.09, relheight=0.15)
        
        # Buttons in the main window
        execute_button = tk.Button(self.master, text='Execute', bg='#e7e7e7', command=lambda: print('Executing'), font=custom_font)
        execute_button.place(relx=0.25, rely=0.93, relwidth=0.19, relheight=0.05)

        close_button = tk.Button(self.master, text='Close', bg='#e7e7e7', command=self.master.destroy, font=custom_font)
        close_button.place(relx=0.6, rely=0.93, relwidth=0.19, relheight=0.05)

    # chose input file widget function
    def choose_input_files(self):
        file_paths = filedialog.askopenfilenames()
        if file_paths:
            file_paths_str = "\n".join(file_paths)
            self.show_local_path.config(text=file_paths_str)
            self.input_file = file_paths[0]  # Store the first selected file for processing

    def create_report_file(self):
            self.report_path = filedialog.asksaveasfilename(defaultextension=".txt", filetypes=[("txt file", "*.txt")])
            if self.report_path:
                self.show_report_path.config(text=self.report_path)
                if hasattr(self, 'diff_result'):
                    self.save_report(self.diff_result, self.report_path)
                    
    # function that handles clicking on 'vypocet' button
    def process_file(self):
        
        print("Starting file processing...")
        self.store_selected_points()

        # get input_file
        input_file = self.input_file
        instrument_type = self.instrument_var.get()
        report_filename = self.report_path

if __name__ == "__main__":
    root = tk.Tk()
    gradmap = App(master=root)
    gradmap.mainloop()
