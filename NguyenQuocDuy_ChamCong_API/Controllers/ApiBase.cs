using Microsoft.AspNetCore.Mvc;

namespace NguyenQuocDuy_ChamCong_API.Controllers;

public abstract class ApiBase : ControllerBase
{
    protected string CurrentUserId => User.FindFirst("uid")?.Value;
}
