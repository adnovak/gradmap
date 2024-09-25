import numpy as np
import pandas as pd
from datetime import datetime
from scipy.stats import t

def gradient_linear(input_file, header_lines, calibration_factor, SD_scale_information, number_of_measured_levels, input_units_option, significance, SD00):
    # File Reading
    filedata = pd.read_csv(input_file, delim_whitespace=True, skiprows=header_lines,
                           names=['Value1', 'Point', 'Height', 'Gravity', 'Error', 'Datetime', 'Value2', 'Value3', 'Value4', 'Value5', 'Value6', 'Value7', 'YY', 'MM', 'DD', 'HHMMSS'])

    # Point ID information
    points = filedata['Point']
    uniquepoints = points.unique()
    pts_num = float(uniquepoints[0]) if uniquepoints[0].replace('.', '', 1).isdigit() else uniquepoints[0]

    measured_station_ID = uniquepoints[0] if isinstance(pts_num, str) else f'{pts_num:8.2f}'

    # Datetime numeric information for each measurement
    dn = filedata['Datetime']
    dtime_t = pd.to_datetime(dn, format='%Y%m%d%H%M%S')
    dtime = dtime_t

    # Height above surface
    if input_units_option == 1:
        height = (filedata['Height'] - 21.1) / 100
    elif input_units_option == 2:
        height = (filedata['Height'] - 0.211)
        if height.mean() > 3:
            height = (filedata['Height'] - 21.1) / 100

    # Measured mGal units converted to μGal
    grav = filedata['Gravity'] * 1000 if calibration_factor is None else filedata['Gravity'] * 1000 * calibration_factor

    # Least Square Adjustment - deterministic model
    n0 = len(points)
    uniquepoints = points.unique()
    k = len(uniquepoints)

    # Drift polynomial degree
    polynomial_degree = 2

    # Jacobi matrix, point section
    A = np.zeros((n0, k))
    level_height = np.zeros((k, 1))

    for i, unique_point in enumerate(uniquepoints):
        ind = points == unique_point
        A[ind, i] = 1
        level_height[i, 0] = height[ind].mean()

    # Jacobi matrix, drift part
    A[:, k] = 1
    for i in range(k + 1, k + 1 + polynomial_degree):
        A[:, i] = (dn - dn.iloc[0]).pow(i - (k + 1))

    # Regularization
    A = np.delete(A, 0, axis=1)

    # Load errors
    ERR = filedata['Error'] * 1000

    # Scaling
    if SD_scale_information == 1:
        ERR = ERR / np.sqrt(60)

    # Weights
    weight = np.mean(ERR) / ERR

    # Weight matrix
    P = np.diag(weight)

    # Covariance matrix of measurements
    Q = np.linalg.inv(P)
    C = SD00**2 * Q

    # Parameter adjustment using LSE formulas
    adjusted_parameters = np.linalg.inv(A.T @ np.linalg.inv(C) @ A) @ A.T @ np.linalg.inv(C) @ grav
    v = A @ adjusted_parameters - grav
    rmse1 = np.sqrt((v.T @ np.linalg.inv(C) @ v) / (n0 - k - 2 - polynomial_degree))
    C_theta = (rmse1**2) * np.linalg.inv(A.T @ np.linalg.inv(C) @ A)
    SD_theta = np.sqrt(np.diag(C_theta))

    # Drift coefficients
    drift_koef = adjusted_parameters[-polynomial_degree:]
    AA = A[:, -polynomial_degree:]

    res_drift = AA @ drift_koef
    test = res_drift + v
    res_drift_av = np.mean(res_drift)

    # Outliers testing
    if significance == 1:
        significance_level = 0.32
        students_inverse_approximate = 480.7 * np.exp(-2.068 * (n0 - k)) + 2.847 * np.exp(-0.000441 * (n0 - k))
    elif significance == 2:
        significance_level = 0.05
        students_inverse_approximate = 43.06 * np.exp(-1.403 * (n0 - k)) + 2.071 * np.exp(-0.0002368 * (n0 - k))
    elif significance == 3:
        significance_level = 0.01
        students_inverse_approximate = 1.633 * np.exp(-0.7396 * (n0 - k)) + 1.013 * np.exp(-7.638e-05 * (n0 - k))

    index_outliers = np.where(np.abs(v) >= SD00 * rmse1 * significance)[0]

    Tau = adjusted_parameters[-1] / SD_theta[-1]

    has_license_for_toolbox = False  # Assuming no statistical toolbox license

    if has_license_for_toolbox:
        students_inverse = 1.0  # Replace with actual tinv() function call
    else:
        students_inverse = students_inverse_approximate

    polynomial_degree_new = 1 if np.abs(Tau) < students_inverse else 2

    # Removing outliers
    grav = np.delete(grav, index_outliers)
    dn = np.delete(dn, index_outliers)
    points = np.delete(points, index_outliers)
    ERR = np.delete(ERR, index_outliers)

    n = len(points)

    # Reprocessing without outliers
    A = np.zeros((n, k))

    for i, unique_point in enumerate(uniquepoints):
        ind = points == unique_point
        A[ind, i] = 1

    A[:, k] = 1
    for i in range(k + 1, k + 1 + polynomial_degree_new):
        A[:, i] = (dn - dn.iloc[0]).pow(i - (k + 1))

    A = np.delete(A, 0, axis=1)

    weight = np.mean(ERR) / ERR
    P = np.diag(weight)
    Q = np.linalg.inv(P)
    C = SD00**2 * Q

    adjusted_parameters_new = np.linalg.inv(A.T @ np.linalg.inv(C) @ A) @ A.T @ np.linalg.inv(C) @ grav
    v = A @ adjusted_parameters_new - grav
    rmse2 = np.sqrt((v.T @ np.linalg.inv(C) @ v) / (n - k - 2 - polynomial_degree_new - 1))
    C_theta = (rmse2**2) * np.linalg.inv(A.T @ np.linalg.inv(C) @ A)
    SD_theta_new = np.sqrt(np.diag(C_theta))

    drift_koef2 = adjusted_parameters_new[-polynomial_degree_new:]
    AA = A[:, -polynomial_degree_new:]

    res_drift_new = AA @ drift_koef2
    res_drift_new_av = np.mean(res_drift_new)

    dtime_t_new = pd.to_datetime(dn, format='%Y%m%d%H%M%S')
    av_height = np.sum(level_height) / number_of_measured_levels

    if number_of_measured_levels == 2:
        if len(uniquepoints) > number_of_measured_levels:
            print('File contains data from more than 2 points - Check point Id for any typos.')
        elif len(uniquepoints) == number_of_measured_levels:
            av_Wzz = adjusted_parameters_new[0] / np.abs(level_height[1] - level_height[0])
            sigma_av_Wzz = np.sqrt((SD_theta_new[0] / np.abs(level_height[1] - level_height[0]))**2)
            av_height = np.sum(level_height) / number_of_measured_levels

    elif number_of_measured_levels == 3:
        if len(uniquepoints) > number_of_measured_levels:
            print('File contains data from more than 3 points - Check point Id for any typos.')
        elif len(uniquepoints) == number_of_measured_levels:
            height_dif = np.abs(level_height[1:] - level_height[0])
            Wzz = adjusted_parameters_new[:2] / height_dif[:2]
            sigma_Wzz = np.sqrt((SD_theta_new[:2] / height_dif[:2])**2)
            Wzz = np.append(Wzz, (adjusted_parameters_new[1] - adjusted_parameters_new[0]) / height_dif[2])
            dg_sigma = np.sqrt(SD_theta_new[0]**2 + SD_theta_new[1]**2)
            sigma_Wzz = np.append(sigma_Wzz, np.sqrt((dg_sigma / height_dif[2])**2))

            av_Wzz = np.mean(Wzz)
            sigma_av_Wzz = np.sqrt(np.sum(sigma_Wzz**2) / number_of_measured_levels)
            av_height = np.sum(level_height) / number_of_measured_levels

    elif number_of_measured_levels == 4:
        if len(uniquepoints) == number_of_measured_levels:
            relg = adjusted_parameters_new[:-polynomial_degree_new-1]
            Dg = np.array([relg[2] - relg[1], relg[1] - relg[0], relg[0], relg[2], relg[2] - relg[0], relg[1]])
            height_dif = np.array([level_height[3] - level_height[2], level_height[2] - level_height[1],
                                   level_height[1] - level_height[0], level_height[3] - level_height[0],
                                   level_height[3] - level_height[1], level_height[2] - level_height[0]])

            Wzz = Dg / height_dif
            av_Wzz = np.mean(Wzz)

            SD_Wzz = np.zeros(6)
            SD_Wzz[0] = np.sqrt((SD_theta[1] / height_dif[0])**2)
            SD_Wzz[1] = np.sqrt((SD_theta[0] / height_dif[1])**2)
            SD_Wzz[2] = np.sqrt((SD_theta[3] / height_dif[2])**2 + (SD_theta[0] / height_dif[2])**2)
            SD_Wzz[3] = np.sqrt((SD_theta[2] / height_dif[3])**2)
            SD_Wzz[4] = np.sqrt((SD_theta[0] / height_dif[4])**2 + (SD_theta[2] / height_dif[4])**2)
            SD_Wzz[5] = np.sqrt((SD_theta[1] / height_dif[5])**2 + (SD_theta[3] / height_dif[5])**2)

            sigma_av_Wzz = np.mean(SD_Wzz)
            av_height = np.sum(level_height) / number_of_measured_levels
        elif len(uniquepoints) < 4:
            print('Why would you measure at more than four levels?')

    output_linear = {
        'stationinfo': {
            'ID': measured_station_ID,
            'filename': input_file.ljust(100),
            'measurement_date': dtime_t_new.iloc[0].strftime('%Y-%m-%d %H:%M:%S')
        },
        'time': {
            'all_measurements': dtime,
            'no_outliers': dtime_t_new,
            'outliers': dtime.iloc[index_outliers].to_list()
        },
        'processing': {
            'number_of_measurements': n0,
            'number_of_rejected_measurements': n0 - n,
            'errors_all': test - res_drift_av,
            'errors_outliers': test.iloc[index_outliers].to_list() - res_drift_av,
            'RMSE': rmse2 * SD00
        },
        'drift': {
            'polynomial_degree': str(polynomial_degree_new),
            'drift_all_measurements': res_drift - res_drift_av,
            'drift_no_outliers': res_drift_new - res_drift_new_av
        },
        'gradient': {
            'average_height': f'{av_height:.3f}',
            'average_gradient': f'{av_Wzz:.1f}',
            'std': f'{sigma_av_Wzz:.1f}',
            'average_height_num': av_height,
            'average_gradient_num': av_Wzz,
            'std_num': sigma_av_Wzz
        }
    }

    return output_linear


def gradient_function(input_file, header_lines, calibration_factor, SD_scale_information, input_units_option, significance, SD00):
    # Read data from file
    filedata = pd.read_csv(input_file, header=header_lines, delimiter=r'\s+',
                           names=['col1', 'points', 'height', 'grav', 'col5', 'col6', 'col7', 'col8', 'col9', 'col10', 'col11', 'dn', 'col13', 'YY', 'col15', 'col16'],
                           dtype={'points': str, 'YY': int})

    # Point ID information
    points = filedata['points']
    uniquepoints = points.unique()
    pts_num = float(uniquepoints[0]) if uniquepoints[0].replace('.', '', 1).isdigit() else uniquepoints[0]

    measured_station_ID = f'{float(uniquepoints[0]):.2f}' if uniquepoints[0].replace('.', '', 1).isdigit() else uniquepoints[0]

    # Datetime numeric information for each measurement (dn)
    dn = filedata['dn']

    # Time information (dtime)
    dtime_t = pd.to_datetime(dn, origin='datenum', unit='D')
    dtime = pd.to_datetime(filedata['YY']*1000000 + filedata['col15']*10000 + filedata['col16']*100 + dtime_t.dt.hour*10000 + dtime_t.dt.minute*100 + dtime_t.dt.second, format='%Y%m%d%H%M%S')

    # Height above surface (mark) - converted to meters
    height = (filedata['height'] - 21.1)/100 if input_units_option == 1 else (filedata['height'] - 0.211)

    # Measured mGal units converted to μGal
    grav = filedata['grav']*1000 if calibration_factor is None else filedata['grav']*1000*calibration_factor

    # Deterministic model
    n0 = len(points)  # number of measurements taken
    k = len(uniquepoints)  # number of measured levels

    # Drift polynomial degrees
    polynomial_degree_time = 2
    polynomial_degree_height = k - 1

    # Jacobi matrix creation - first column
    A = np.ones((n0, 1))

    # Jacobi matrix - 2nd part: height section
    for i in range(2, polynomial_degree_height + 2):
        A = np.column_stack([A, height**(i - 1)])

    # Jacobi matrix - 3rd part: drift section
    for i in range(polynomial_degree_height + 2, polynomial_degree_height + 2 + polynomial_degree_time):
        A = np.column_stack([A, (dn - dn.iloc[0])**(i - (1 + polynomial_degree_height))])

    # Load errors from filedata and transfer from mGal to μGal
    ERR = filedata['col5']*1000

    # Scale errors
    if SD_scale_information == 1:
        ERR = ERR / np.sqrt(60)

    # Weights
    weight = np.mean(ERR) / ERR

    # Weight matrix
    P = np.diag(weight)

    # Covariance matrix of measurements
    Q = np.linalg.inv(P)
    C = (SD00**2) * Q

    # Parameter adjustment using LSE formulas
    adjusted_parameters = np.linalg.inv(A.T @ np.linalg.inv(C) @ A) @ A.T @ np.linalg.inv(C) @ grav

    # Measurement errors to adjusted parameters
    v = A @ adjusted_parameters - grav

    # Root mean square error
    rmse1 = np.sqrt((v.T @ np.linalg.inv(C) @ v) / (n0 - len(A.T) - 1))

    # Covariance matrix of adjusted parameters
    C_theta = (rmse1**2) * np.linalg.inv(A.T @ np.linalg.inv(C) @ A)

    # Standard deviation of adjusted parameters
    SD_theta = np.sqrt(np.diag(C_theta))

    # Drift coefficients
    drift_koef = adjusted_parameters[-polynomial_degree_time:]
    A_drift = A[:, -polynomial_degree_time:]

    # Residual (transportation drift)
    res_drift = A_drift @ drift_koef

    # Test values
    test1 = res_drift + v

    # Average drift value to subtract later
    res_drift_av = np.mean(res_drift)

    # Outliers testing
    if significance == 1:
        significance_level = 0.32
        students_inverse_approximate = 480.7 * np.exp(-2.068 * (n0 - len(A.T))) + 2.847 * np.exp(-0.000441 * (n0 - len(A.T)))

    elif significance == 2:
        significance_level = 0.05
        students_inverse_approximate = 43.06 * np.exp(-1.403 * (n0 - len(A.T))) + 2.071 * np.exp(-0.0002368 * (n0 - len(A.T)))

    elif significance == 3:
        significance_level = 0.01
        students_inverse_approximate = 1.633 * np.exp(-0.7396 * (n0 - len(A.T))) + 1.013 * np.exp(-7.638e-05 * (n0 - len(A.T)))

    # Outliers indexes
    index_outliers = np.where(np.abs(v) >= SD00 * rmse1 * significance)[0]

    # Statistical testing of parameters
    Tau1 = adjusted_parameters[-1] / SD_theta[-1]
    Tau2 = adjusted_parameters[-polynomial_degree_time] / SD_theta[-polynomial_degree_time]

    # Quadratic component significance testing
    has_license_for_toolbox = False  # Please replace this with your own check for the Statistics Toolbox

    if not has_license_for_toolbox:
        students_inverse = students_inverse_approximate

        if np.abs(Tau1) < students_inverse:
            polynomial_degree_time_final = polynomial_degree_time - 1
        else:
            polynomial_degree_time_final = polynomial_degree_time

        if np.abs(Tau2) < students_inverse:
            polynomial_degree_height_new = polynomial_degree_height - 1
        else:
            polynomial_degree_height_new = polynomial_degree_height

    else:
        students_inverse = t.ppf(1 - (significance_level) / 2, n0 - len(A.T))

        if np.abs(Tau1) < students_inverse:
            polynomial_degree_time_final = 1
        else:
            polynomial_degree_time_final = 2

        if np.abs(Tau2) < students_inverse:
            polynomial_degree_height_new = polynomial_degree_height - 1
        else:
            polynomial_degree_height_new = polynomial_degree_height

    # Removing outliers 1
    grav_new = np.delete(grav, index_outliers)
    dn_new = np.delete(dn, index_outliers)
    points_new = np.delete(points, index_outliers)
    ERR_new = np.delete(ERR, index_outliers)
    YY_new = np.delete(filedata['YY'], index_outliers)
    height_new = np.delete(height, index_outliers)

    # Reprocessing without outliers 1
    A = np.ones((len(points_new), 1))

    for i in range(2, polynomial_degree_height_new + 2):
        A = np.column_stack([A, height_new**(i - 1)])

    for i in range(polynomial_degree_height_new + 2, polynomial_degree_height_new + 2 + polynomial_degree_time_final):
        A = np.column_stack([A, (dn_new - dn_new[0])**(i - (1 + polynomial_degree_height_new))])

    nrows, lgt = A.shape

    # Weights
    weight = np.mean(ERR_new) / ERR_new

    # Weight matrix
    P = np.diag(weight)

    # Covariance matrix of measurements
    Q = np.linalg.inv(P)
    C = (SD00**2) * Q

    # Parameter adjustment without outliers 1
    adjusted_parameters_new = np.linalg.inv(A.T @ np.linalg.inv(C) @ A) @ A.T @ np.linalg.inv(C) @ grav_new

    # Measurement errors to adjusted parameters
    v_new = A @ adjusted_parameters_new - grav_new

    # Root mean square error
    rmse2 = np.sqrt((v_new.T @ np.linalg.inv(C) @ v_new) / (nrows - lgt))

    # Covariance matrix of adjusted parameters
    C_theta = (rmse2**2) * np.linalg.inv(A.T @ np.linalg.inv(C) @ A)

    # Standard deviation of adjusted parameters
    SD_theta_new = np.sqrt(np.diag(C_theta))

    # Drift coefficients
    drift_koef = adjusted_parameters_new[-polynomial_degree_time_final:]
    A_drift = A[:, -polynomial_degree_time_final:]

    # Residual (transportation drift)
    res_drift_new = A_drift @ drift_koef

    # Test values
    test2 = res_drift_new + v_new

    # Average drift value to subtract later
    res_drift_av_new = np.mean(res_drift_new)

    # Time information (datetime) for reprocessed data without outliers 1
    dtime_t_new = pd.to_datetime(dn_new, origin='datenum', unit='D')
    dtime_new = pd.to_datetime(YY_new*1000000 + dtime_t_new.dt.month*10000 + dtime_t_new.dt.day*100 + dtime_t_new.dt.hour*10000 + dtime_t_new.dt.minute*100 + dtime_t_new.dt.second, format='%Y%m%d%H%M%S')

    # Outliers indexes after reprocessing without outliers 1
    index_outliers_new = np.where(np.abs(v_new) >= SD00 * rmse2 * significance)[0]

    # Statistical testing of parameters
    Tau2_new = adjusted_parameters_new[-polynomial_degree_time_final] / SD_theta_new[-polynomial_degree_time_final]

    # Quadratic component significance testing (2nd round)
    if not has_license_for_toolbox:

        if np.abs(Tau2_new) < np.sqrt(students_inverse_approximate):
            polynomial_degree_height_final = polynomial_degree_height_new - 1
        else:
            polynomial_degree_height_final = polynomial_degree_height_new

    else:
        students_inverse = t.ppf(1 - (significance_level) / 2, nrows - lgt)

        if np.abs(Tau2_new) < np.sqrt(students_inverse):
            polynomial_degree_height_final = polynomial_degree_height_new - 1
        else:
            polynomial_degree_height_final = polynomial_degree_height_new

    # Removing outliers 2
    grav_final = np.delete(grav_new, index_outliers_new)
    dn_final = np.delete(dn_new, index_outliers_new)
    points_final = np.delete(points_new, index_outliers_new)
    ERR_final = np.delete(ERR_new, index_outliers_new)
    YY_final = np.delete(YY_new, index_outliers_new)
    height_final = np.delete(height_new, index_outliers_new)

    # Reprocessing without outliers 2
    A = np.ones((len(points_final), 1))

    for i in range(2, polynomial_degree_height_final + 2):
        A = np.column_stack([A, height_final**(i - 1)])

    for i in range(polynomial_degree_height_final + 2, polynomial_degree_height_final + 2 + polynomial_degree_time_final):
        A = np.column_stack([A, (dn_final - dn_final[0])**(i - (1 + polynomial_degree_height_final))])

    nrows, lgt = A.shape

    # Weights
    weight = np.mean(ERR_final) / ERR_final

    # Weight matrix
    P = np.diag(weight)

    # Covariance matrix of measurements
    Q = np.linalg.inv(P)
    C = (SD00**2) * Q

    # Parameter adjustment without outliers 2
    adjusted_parameters_final = np.linalg.inv(A.T @ np.linalg.inv(C) @ A) @ A.T @ np.linalg.inv(C) @ grav_final

    # Measurement errors to adjusted parameters
    v_final = A @ adjusted_parameters_final - grav_final

    # Root mean square error
    rmse3 = np.sqrt((v_final.T @ np.linalg.inv(C) @ v_final) / (nrows - lgt))

    # Covariance matrix of adjusted parameters
    C_theta = (rmse3**2) * np.linalg.inv(A.T @ np.linalg.inv(C) @ A)

    # Standard deviation of adjusted parameters
    SD_theta_final = np.sqrt(np.diag(C_theta))

    # Drift coefficients
    drift_koef = adjusted_parameters_final[-polynomial_degree_time_final:]
    A_drift = A[:, -polynomial_degree_time_final:]

    # Residual (transportation drift)
    res_drift_final = A_drift @ drift_koef

    # Test values
    test_final = res_drift_final + v_final

    # Average drift value to subtract later
    res_drift_av_final = np.mean(res_drift_final)

    # Time information (datetime) for reprocessed data without outliers 2
    dtime_t_final = pd.to_datetime(dn_final, origin='datenum', unit='D')
    dtime_final = pd.to_datetime(YY_final*1000000 + dtime_t_final.dt.month*10000 + dtime_t_final.dt.day*100 + dtime_t_final.dt.hour*10000 + dtime_t_final.dt.minute*100 + dtime_t_final.dt.second, format='%Y%m%d%H%M%S')

    # Output dictionary
    output_function = {
        'stationinfo': {
            'ID': measured_station_ID,
            'filename': input_file.ljust(100),
            'measurement_date': str(dtime_new.iloc[0]),
        },
        'time': {
            'all_measurements': dtime,
            'no_outliers': dtime_final,
        },
        'processing': {
            'number_of_measurements': nrows,
            'number_of_rejected_measurements': n0 - nrows,
            'errors_all': (test1 - res_drift_av).tolist(),
            'outliers_removed': (test_final - res_drift_av_final).tolist(),
            'RMSE': rmse3 * SD00,
        },
        'drift': {
            'polynomial_degree': str(polynomial_degree_time_final),
            'drift_all_measurements': (res_drift - res_drift_av).tolist(),
            'drift_no_outliers': (res_drift_final - res_drift_av_final).tolist(),
        },
        'gradient': {
            'polynomial_degree': str(polynomial_degree_height_final),
            'gradient_param': adjusted_parameters_final[1:polynomial_degree_height_final + 1].tolist() + [0] * (3 - polynomial_degree_height_final),
            'std': SD_theta_final[1:polynomial_degree_height_final + 1].tolist() + [0] * (3 - polynomial_degree_height_final),
        },
    }

    return output_function

def gravity_differences(input_file, header_lines, significance, SD_scale_information, instrument_type):
    try:
        
        # Search for the line containing "GCAL1" in the header
        header_line_number = None
        with open(input_file, 'r') as file:
            for i, line in enumerate(file):
                if "Gcal1" in line:
                    header_line_number = i
                    header_info = line.strip()
                    break
        
        # Check if the line with "GCAL1" was found
        if header_line_number is None:
            raise ValueError("The word 'GCAL1' was not found in the file.")
        
        GCAL1_str = header_info[9:]
        GCAL1 = float(GCAL1_str)
                
        # Search for the line containing "GCAL1" in the header
        header_line_number = None
        with open(input_file, 'r') as file:
            for i, line in enumerate(file):
                if "Instrument S/N" in line:
                    header_line_number = i
                    header_info = line.strip()
                    break
        
        # Check if the line with "Serial number of instrument" was found
        if header_line_number is None:
            raise ValueError("The word 'GCAL1' was not found in the file.")
        SN_str = header_info[17:]
        
        # # Read data from file
        filedata = pd.read_csv(input_file, header=header_lines, delimiter=r'\s+', 
                                names=['col1', 'points', 'height', 'grav', 'SD', 'tiltx', 'tilty', 'temp_corr', 'tide_corr', 'duration', 'rejected', 'time', 'dn', 'terrain_col', 'date'],
                                dtype={'points': str, 'height':float, 'time': str})
    
        # Combine date and time into datetime column
        filedata['datetime'] = pd.to_datetime(filedata['date'] + ' ' + filedata['time'], format='%Y/%m/%d %H:%M:%S')
        dtime = filedata['datetime']
        
        # Convert datetime to numeric date format (days since Unix epoch)
        dn = filedata['datetime'].apply(lambda x: x.timestamp() / (24 * 3600))
        
        if instrument_type == 'Scintrex CG5':
            
            # Determine the adjustment based on testheight
            if filedata['height'].iloc[0] > 2:
                # Convert centimeters to meters: Subtract 21.1 and divide by 100
                filedata['height'] = (filedata['height'] - 21.1) / 100
            else:
                # Assume default units are meters: Subtract 0.211
                filedata['height'] = filedata['height'] - 0.211
        
        # Convert measured mGal units to μGal
        grav = filedata['grav'] * 1000
        # Reducing measured values to a point using normal gradient
        grav = grav + filedata['height'] * 308.6
        # Point ID information
        points = filedata['points']
        uniquepoints = filedata['points'].unique()
        measured_points = [p if p.isdigit() else f'{float(p):8.2f}' for p in uniquepoints]
        # Least Square Adjustment - deterministic model
        n0 = len(filedata['points'])  # number of measurements taken
        k = len(uniquepoints)  # number of measured points
        
        # starting drift polynomial degree
        polynomial_degree = 2
        
        # Jacobi matrix, point section
        A = np.zeros((n0, k))
        for i, unique_point in enumerate(uniquepoints):
            ind = points == unique_point
            A[ind, i] = 1
        
        # Jacobi matrix, drift part
        A = np.column_stack([A, np.ones(n0)])
        for i in range(k + 2 , k + 2 + polynomial_degree):
            A = np.column_stack([A, (dn - dn[0])**(i - k - 1)])
        # Regularization - by default first column is removed to fix position 1 as starting 
        A = np.delete(A, 0, axis=1)
        # # Load errors from filedata and transfer from miliGal to microGal
        ERR = filedata['SD'] * 1000
        # Scale errors
        if SD_scale_information == 1:
            ERR = ERR / np.sqrt(60)
            
        C = np.diag(np.square(ERR))
        # Parameter adjustment using LSE formulas
        adjusted_parameters = np.linalg.inv(A.T @ np.linalg.inv(C) @ A) @ A.T @ np.linalg.inv(C) @ grav
        # Measurement errors to adjusted parameters
        v = A @ adjusted_parameters - grav
        # Root mean square error
        rmse1 = np.sqrt((v.T @ np.linalg.inv(C) @ v) / (n0 - k - 2 - polynomial_degree))
        # Covariance matrix of adjusted parameters
        C_theta = (rmse1**2) * np.linalg.inv(A.T @ np.linalg.inv(C) @ A)
        # Standard deviation of adjusted parameters
        SD_theta = np.sqrt(np.diag(C_theta))
        # Drift coefficients
        drift_koef = adjusted_parameters[-polynomial_degree:]
        AA = A[:, -polynomial_degree:]
        # Residual (transportation drift)
        res_drift = AA @ drift_koef
        # Test values
        test = res_drift + v
        # Average drift value to subtract later
        res_drift_av = np.mean(res_drift)
        # Outliers testing
        if significance == 1:
            significance_level = 0.32
        
        elif significance == 2:
            significance_level = 0.05
        
        elif significance == 3:
            significance_level = 0.01
        
        # Outliers indexes
        index_outliers = np.where(np.abs(v) >= 5 *3* rmse1 * significance)[0]
        # Statistical testing of parameters
        Tau = adjusted_parameters[-1] / SD_theta[-1]
        # Quadratic component significance testing
        
        t_value = stats.t.ppf(1-significance_level/2, n0-k)
        
        if np.abs(Tau) < t_value:
            polynomial_degree_new = 1  # Drift approx. function set to linear
        else:
            polynomial_degree_new = 2  # Drift approx. function remains quadratic
        
        # Removing outliers
        grav = np.delete(grav, index_outliers)
        dn = np.delete(dn, index_outliers)
        points = np.delete(points, index_outliers)
        ERR = np.delete(ERR, index_outliers)
        
        n = len(points)
        A = np.zeros((n, k))
        for i, unique_point in enumerate(uniquepoints):
            ind = points == unique_point
            A[ind, i] = 1
        
        # Jacobi matrix, drift part
        A = np.column_stack([A, np.ones(n)])
        for i in range(k + 2 , k + 2 + polynomial_degree):
            A = np.column_stack([A, (dn - dn[0])**(i - k - 1)])
            
        # Regularization - by default first column is removed to fix position 1 as starting 
        A = np.delete(A, 0, axis=1)
        C = np.square(np.diag(ERR))
        
        # New adjusted parameters without considering outliers in the processing
        adjusted_parameters_new = np.linalg.inv(A.T @ np.linalg.inv(C) @ A) @ A.T @ np.linalg.inv(C) @ grav
        
        # Measurements errors to adjusted parameters
        v = A @ adjusted_parameters_new - grav
        rmse2 = np.sqrt((v.T @ np.linalg.inv(C) @ v) / (n - k - 2 - polynomial_degree_new - 1))
        C_theta = (rmse2**2) * np.linalg.inv(A.T @ np.linalg.inv(C) @ A)
        SD_theta_new = np.sqrt(np.diag(C_theta))
        
        drift_koef2 = adjusted_parameters_new[-polynomial_degree_new:]
        AA = A[:, -polynomial_degree_new:]
        
        # New drift
        res_drift_new = AA @ drift_koef2
        res_drift_new_av = np.mean(res_drift_new)
        
        # new Time information dtime (datetime)
        dtime_new = pd.to_datetime(dn, unit='D', origin='unix')
        
        # Output dictionary
        output_gravity_diff = {
            'stationinfo': {
                'filename': input_file.ljust(100),
                'measurement_date': str(dtime_new[0]),
                'measuredpoints': measured_points
            },
            'time': {
                'all_measurements': dtime,
                'no_outliers': dtime_new,
                'outliers': dtime.iloc[index_outliers].tolist()
            },
            'processing': {
                'number_of_measurements': n0,
                'rejected_measurements': n0 - n,
                'RMSE': rmse2,
                'errors_all': (test - res_drift_av).tolist(),
                'errors_outliers': (test.iloc[index_outliers] - res_drift_av).tolist()
            },
            'drift': {
                'polynomial_degree': str(polynomial_degree_new),
                'drift_all_measurements': (res_drift - res_drift_av).tolist(),
                'drift_no_outliers': (res_drift_new - res_drift_new_av).tolist()
            },
            'adjusted': {
                'differences': adjusted_parameters_new[:len(uniquepoints)-1].tolist(),
                'std': SD_theta_new[:len(uniquepoints)-1].tolist()
            },
            'instrument_info': {
                'GCAL1':GCAL1,
                'SN':SN_str
                }
        }
        return output_gravity_diff
    except Exception as e:
        print(f"Error in gravity_differences: {e}")
        raise
