using Microsoft.AspNetCore.Identity;

namespace NguyenQuocDuy_ChamCong_API.Models;

public class AppUser : IdentityUser
{
    public string FullName { get; set; } = "";
}

public class Department
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public List<Employee> Employees { get; set; } = new();
}

public class Employee
{
    public int Id { get; set; }
    public string Code { get; set; } = "";
    public string FullName { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Position { get; set; } = "";
    public bool IsActive { get; set; } = true;
    public int? DepartmentId { get; set; }
    public Department Department { get; set; }
    public string UserId { get; set; }
}

public class Shift
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public int LateGraceMinutes { get; set; } = 10;
}

public class WorkSite
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public int RadiusMeters { get; set; } = 200;
}

public class Attendance
{
    public int Id { get; set; }
    public int EmployeeId { get; set; }
    public Employee Employee { get; set; }
    public DateTime WorkDate { get; set; }
    public DateTime CheckInTime { get; set; }
    public DateTime? CheckOutTime { get; set; }
    public double? CheckInLat { get; set; }
    public double? CheckInLng { get; set; }
    public double? CheckOutLat { get; set; }
    public double? CheckOutLng { get; set; }
    public string Method { get; set; } = "GPS";      // QR | GPS | Manual
    public string Status { get; set; } = "DungGio";  // DungGio | DiTre | NghiPhep
    public string Note { get; set; } = "";
    public bool MotionVerified { get; set; }
    public int WorkedMinutes { get; set; }
}

public class LeaveRequest
{
    public int Id { get; set; }
    public int EmployeeId { get; set; }
    public Employee Employee { get; set; }
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string Reason { get; set; } = "";
    public string Status { get; set; } = "ChoDuyet"; // ChoDuyet | DaDuyet | TuChoi
    public string AdminNote { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.Now;
}

public class LocationShare
{
    public int Id { get; set; }
    public int EmployeeId { get; set; }
    public Employee Employee { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.Now;
    public bool IsSharing { get; set; } = true;
}

public class Feedback
{
    public int Id { get; set; }
    public string UserId { get; set; } = "";
    public string CustomerName { get; set; } = "";
    public int? EmployeeId { get; set; }
    public Employee Employee { get; set; }
    public int Rating { get; set; } = 5;
    public string Content { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.Now;
}
