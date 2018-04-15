(function() {
	'use strict';

	var STATUS_CLASS_MAP = {
		ok: ['alert', 'alert-info'],
		warning: ['alert', 'alert-warning'],
		critical: ['alert', 'alert-danger']
	};

	angular.module('StatusDashboard').directive('unhandledRedmineIssues', [
		'statusService',
		function(statusService) {
			return {
				restrict:    'E',
				link :       function(scope, element, attrs) {
					scope.issues = [];

					scope.$watch(
						function() {
							return statusService.getStatus(scope.statusId)
						},
						function(newValue, oldValue) {
							if (newValue === null) {
								return;
							}
							scope.issues = newValue.issues.map(function (issue) {
								issue.statusClass = STATUS_CLASS_MAP[issue.status];
								return issue;
							});
						}
					);
					scope.$watch('priorityClassStr', function (newValue, oldValue) {
						scope.priorityClass = scope.$eval(newValue);
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/unhandled-redmine-issues.html',
				scope:       {
					statusId:         '@statusId',
					statusTitle:      '@statusTitle',
					count:            '@count',
					priorityClassStr: '@priorityClass',
				}
			}
		}
	]);
}());
