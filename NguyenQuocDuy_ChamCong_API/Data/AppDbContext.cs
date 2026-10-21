 using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using NguyenQuocDuy_ChamCong_API.Models;

namespace NguyenQuocDuy_ChamCong_API.Data;

public class AppDbContext : IdentityDbContext<AppUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Department> Departments { get; set; }
    public DbSet<Employee> Employees { get; set; }
    public DbSet<Shift> Shifts { get; set; }
    public DbSet<WorkSite> WorkSites { get; set; }
    public DbSet<Attendance> Attendances { get; set; }
    public DbSet<LeaveRequest> LeaveRequests { get; set; }
    public DbSet<LocationShare> LocationShares { get; set; }
    public DbSet<Feedback> Feedbacks { get; set; }

    protected override void OnModelCreating(ModelBuilder b)
    {
        base.OnModelCreating(b);

        b.Entity<Employee>()
            .HasOne(e => e.Department).WithMany(d => d.Employees)
            .HasForeignKey(e => e.DepartmentId).OnDelete(DeleteBehavior.SetNull);

        b.Entity<Attendance>()
            .HasOne(a => a.Employee).WithMany()
            .HasForeignKey(a => a.EmployeeId).OnDelete(DeleteBehavior.Cascade);
        b.Entity<Attendance>().HasIndex(a => new { a.EmployeeId, a.WorkDate }).IsUnique();

        b.Entity<LeaveRequest>()
            .HasOne(l => l.Employee).WithMany()
            .HasForeignKey(l => l.EmployeeId).OnDelete(DeleteBehavior.Cascade);

        b.Entity<LocationShare>()
            .HasOne(l => l.Employee).WithMany()
            .HasForeignKey(l => l.EmployeeId).OnDelete(DeleteBehavior.Cascade);
        b.Entity<LocationShare>().HasIndex(l => l.EmployeeId).IsUnique();

        b.Entity<Feedback>()
            .HasOne(f => f.Employee).WithMany()
            .HasForeignKey(f => f.EmployeeId).OnDelete(DeleteBehavior.SetNull);
    }
}
